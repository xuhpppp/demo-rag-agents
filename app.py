import json
import os

from dotenv import load_dotenv
from fastapi import FastAPI, UploadFile
from fastapi.responses import FileResponse, StreamingResponse
from pydantic import BaseModel
from langchain_aws import ChatBedrock
from langchain_core.tools import tool
from langchain.agents import create_agent

from agents.synthea_sql_agent import create_sql_agent
from queue_manager import file_queue, FileJob
from consumer import consume

load_dotenv()

# Initialize the SQL sub-agent
sql_agent = create_sql_agent()


@tool
def query_synthea_database(question: str) -> str:
    """Query the Synthea patient database using natural language.
    Use this tool when the user asks about patient data, conditions,
    medications, encounters, or any healthcare-related data stored in the database.
    """
    result = sql_agent.invoke({"messages": [{"role": "user", "content": question}]})
    return result["messages"][-1].content


# Initialize the orchestrator model
orchestrator_model = ChatBedrock(
    model="jp.anthropic.claude-sonnet-4-6",
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
    aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
    region_name=os.getenv("AWS_REGION"),
)

# Create orchestrator agent
orchestrator = create_agent(
    model=orchestrator_model,
    tools=[query_synthea_database],
    system_prompt="""You are a helpful healthcare data assistant.
You can answer questions about patient data by querying the Synthea database.

When the user asks about patients, conditions, medications, encounters,
or any healthcare data, use the query_synthea_database tool.

For general questions not related to the database, answer directly.

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


@app.get("/vectors")
def vectors_count():
    from consumer import parent_collection, child_collection
    return {
        "parent_chunks": parent_collection.count(),
        "child_chunks": child_collection.count(),
    }


@app.delete("/vectors")
def vectors_clear():
    from consumer import chroma_client, bedrock_ef, parent_collection, child_collection
    import consumer

    chroma_client.delete_collection("parent_chunks")
    chroma_client.delete_collection("child_chunks")
    consumer.parent_collection = chroma_client.get_or_create_collection(
        "parent_chunks", embedding_function=bedrock_ef
    )
    consumer.child_collection = chroma_client.get_or_create_collection(
        "child_chunks", embedding_function=bedrock_ef
    )
    return {"status": "cleared"}


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
