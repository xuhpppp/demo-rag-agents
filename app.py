import json
import os

from dotenv import load_dotenv
from fastapi import FastAPI, UploadFile
from fastapi.responses import FileResponse, StreamingResponse
from pydantic import BaseModel
from langchain_aws import ChatBedrock
from langchain_openai import ChatOpenAI
from langchain_chroma import Chroma
from langchain_core.tools import tool
from langchain.agents import create_agent

from langfuse.langchain import CallbackHandler

from agents.synthea_sql_agent import create_sql_agent
from agents.rag_agent import create_rag_agent
from agents.single_agent import create_single_agent
from queue_manager import file_queue, FileJob
from consumer import consume

load_dotenv()

# Initialize Langfuse callback handler for tracing
langfuse_handler = CallbackHandler()


# ---------------------------------------------------------------------------
# Model factories
# ---------------------------------------------------------------------------

def get_bedrock_model(role="default"):
    kwargs = dict(
        max_tokens=10024,
        streaming=True,
        aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
        aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
        region_name=os.getenv("AWS_REGION"),
    )
    if role == "light":
        return ChatBedrock(model="jp.anthropic.claude-haiku-4-5-20251001-v1:0", **kwargs)
    return ChatBedrock(model="jp.anthropic.claude-sonnet-4-6", **kwargs)


def get_openai_model():
    return ChatOpenAI(
        api_key=os.getenv("OPENAI_API_KEY"),
        streaming=True,
        model="gpt-5.4-mini-2026-03-17",
        max_tokens=10024,
    )


# ---------------------------------------------------------------------------
# Orchestrator prompt (shared across providers)
# ---------------------------------------------------------------------------

ORCHESTRATOR_PROMPT = """You are a helpful healthcare data assistant with access to two tools:

1. **query_synthea_database** - Query the Synthea patient database for actual patient data,
   conditions, medications, encounters, and healthcare statistics.
2. **search_medical_guidelines** - Search uploaded medical guidelines and protocols for
   clinical recommendations, treatment standards, and healthcare policies.

Use query_synthea_database when the user asks about patient data or database statistics.
Use search_medical_guidelines when the user asks about guidelines, protocols, or recommendations.
Use BOTH tools when the user wants to compare guidelines with actual patient data.

When your answer includes information from medical guidelines, preserve the inline
citations exactly as returned by the search_medical_guidelines tool (e.g. [filename.txt]).
Include a "Sources" section at the end listing all cited documents.

For general questions not related to the database or guidelines, answer directly.

When presenting tabular data, you MUST use proper markdown table syntax with a header
separator row. Example:

| Column A | Column B |
|----------|----------|
| value 1  | value 2  |

Never use pipe characters for anything other than markdown tables."""


# ---------------------------------------------------------------------------
# Lazy agent cache — agents are created on first request per provider
# ---------------------------------------------------------------------------

_agent_cache = {}


def _build_orchestrator(provider):
    if provider == "bedrock":
        orch_model = get_bedrock_model()
        sql_model = get_bedrock_model()
        rag_model = get_bedrock_model("light")
    else:
        orch_model = get_openai_model()
        sql_model = get_openai_model()
        rag_model = get_openai_model()

    sql_sub = create_sql_agent(sql_model)
    rag_sub = create_rag_agent(rag_model)

    @tool
    def query_synthea_database(question: str) -> str:
        """Query the Synthea patient database using natural language.
        Use this tool when the user asks about patient data, conditions,
        medications, encounters, or any healthcare-related data stored in the database.
        """
        result = sql_sub.invoke(
            {"messages": [{"role": "user", "content": question}]},
            config={"callbacks": [langfuse_handler]},
        )
        return result["messages"][-1].content

    @tool
    def search_medical_guidelines(question: str) -> str:
        """Search medical guidelines and protocols from uploaded documents.
        Use this tool when the user asks about healthcare guidelines, treatment protocols,
        clinical recommendations, or medical standards from the knowledge base.
        """
        result = rag_sub.invoke(
            {"messages": [{"role": "user", "content": question}]},
            config={"callbacks": [langfuse_handler]},
        )
        return result["messages"][-1].content

    return create_agent(
        debug=True,
        model=orch_model,
        tools=[query_synthea_database, search_medical_guidelines],
        system_prompt=ORCHESTRATOR_PROMPT,
    )


def get_agent(provider: str, agent_type: str):
    key = f"{provider}:{agent_type}"
    if key not in _agent_cache:
        if agent_type == "orchestrator":
            _agent_cache[key] = _build_orchestrator(provider)
        else:
            model = get_bedrock_model() if provider == "bedrock" else get_openai_model()
            _agent_cache[key] = create_single_agent(model)
    return _agent_cache[key]

app = FastAPI()


@app.on_event("startup")
async def startup():
    import asyncio
    asyncio.create_task(consume())


@app.on_event("shutdown")
async def shutdown():
    langfuse_handler.langfuse.shutdown()


class ChatRequest(BaseModel):
    message: str
    agent: str = "orchestrator"
    provider: str = "openai"


UPLOAD_DIR = "uploads"


@app.get("/")
def index():
    return FileResponse("static/index.html")


@app.get("/upload")
def upload_page():
    return FileResponse("static/upload.html")


@app.post("/upload")
async def upload_file(file: UploadFile):
    if not file.filename.endswith(".txt"):
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail=".txt ファイルのみアップロードできます")

    filepath = os.path.join(UPLOAD_DIR, file.filename)
    contents = await file.read()
    with open(filepath, "wb") as f:
        f.write(contents)

    job = FileJob(filename=file.filename, filepath=filepath, size_bytes=len(contents))
    await file_queue.push(job)

    return {"filename": file.filename}


@app.post("/chat")
def chat(req: ChatRequest):
    active_agent = get_agent(req.provider, req.agent)

    def generate():
        for chunk, metadata in active_agent.stream(
            {"messages": [{"role": "user", "content": req.message}]},
            stream_mode="messages",
            config={"callbacks": [langfuse_handler]},
        ):
            if metadata["langgraph_node"] == "model":
                if isinstance(chunk.content, list):
                    for block in chunk.content:
                        if block.get("type") == "text":
                            yield f"data: {json.dumps(block['text'])}\n\n"
                elif isinstance(chunk.content, str) and chunk.content:
                    yield f"data: {json.dumps(chunk.content)}\n\n"
        yield "data: [DONE]\n\n"

    return StreamingResponse(generate(), media_type="text/event-stream")


@app.delete("/vectors")
def vectors_clear():
    from consumer import chroma_client, embeddings
    import consumer

    chroma_client.delete_collection("example_collection")
    consumer.vector_store = Chroma(
        client=chroma_client,
        collection_name="example_collection",
        embedding_function=embeddings,
        collection_metadata={"hnsw:space": "cosine"},
    )
    return {"status": "cleared"}