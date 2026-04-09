import json
import os

from dotenv import load_dotenv
from fastapi import FastAPI, UploadFile
from fastapi.responses import FileResponse, StreamingResponse
from pydantic import BaseModel
from langchain_aws import ChatBedrock
from langchain_chroma import Chroma
from langchain_core.tools import tool
from langchain.agents import create_agent

from agents.synthea_sql_agent import create_sql_agent
from agents.rag_agent import create_rag_agent
from queue_manager import file_queue, FileJob
from consumer import consume

load_dotenv()

# Initialize sub-agents
sql_agent = create_sql_agent()
rag_agent = create_rag_agent()


@tool
def query_synthea_database(question: str) -> str:
    """Query the Synthea patient database using natural language.
    Use this tool when the user asks about patient data, conditions,
    medications, encounters, or any healthcare-related data stored in the database.
    """
    result = sql_agent.invoke({"messages": [{"role": "user", "content": question}]})
    return result["messages"][-1].content


@tool
def search_medical_guidelines(question: str) -> str:
    """Search medical guidelines and protocols from uploaded documents.
    Use this tool when the user asks about healthcare guidelines, treatment protocols,
    clinical recommendations, or medical standards from the knowledge base.
    """
    result = rag_agent.invoke({"messages": [{"role": "user", "content": question}]})
    return result["messages"][-1].content


# Initialize the orchestrator model
orchestrator_model = ChatBedrock(
    model="jp.anthropic.claude-haiku-4-5-20251001-v1:0",
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
    aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
    region_name=os.getenv("AWS_REGION"),
)

# Create orchestrator agent
orchestrator = create_agent(
    model=orchestrator_model,
    tools=[query_synthea_database, search_medical_guidelines],
    system_prompt="""You are a helpful healthcare data assistant with access to two tools:

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

Never use pipe characters for anything other than markdown tables.""",
)

app = FastAPI()


@app.on_event("startup")
async def startup():
    import asyncio
    asyncio.create_task(consume())


class ChatRequest(BaseModel):
    message: str


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
    def generate():
        for chunk, metadata in orchestrator.stream(
            {"messages": [{"role": "user", "content": req.message}]},
            stream_mode="messages",
        ):
            if metadata["langgraph_node"] == "model" and isinstance(
                chunk.content, list
            ):
                for block in chunk.content:
                    if block.get("type") == "text":
                        yield f"data: {json.dumps(block['text'])}\n\n"
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