import asyncio
import logging
import os
import uuid

import chromadb
from chromadb.api.types import EmbeddingFunction, Documents, Embeddings
from dotenv import load_dotenv
from langchain_aws import BedrockEmbeddings
from langchain_text_splitters import RecursiveCharacterTextSplitter

from queue_manager import file_queue

load_dotenv()

logger = logging.getLogger(__name__)


class BedrockEmbeddingFunction(EmbeddingFunction):
    """Wrap LangChain BedrockEmbeddings as a ChromaDB EmbeddingFunction."""

    def __init__(self):
        self._embeddings = BedrockEmbeddings(
            model_id="amazon.titan-embed-text-v2:0",
            region_name=os.getenv("AWS_REGION"),
        )

    def __call__(self, input: Documents) -> Embeddings:
        return self._embeddings.embed_documents(input)


bedrock_ef = BedrockEmbeddingFunction()

# ChromaDB client (HTTP connection to Docker container)
chroma_client = chromadb.HttpClient(
    host=os.getenv("CHROMA_HOST", "localhost"),
    port=int(os.getenv("CHROMA_PORT", "8001")),
)

# Collections: parents hold large context chunks, children hold small retrieval chunks
parent_collection = chroma_client.get_or_create_collection(
    "parent_chunks", embedding_function=bedrock_ef
)
child_collection = chroma_client.get_or_create_collection(
    "child_chunks", embedding_function=bedrock_ef
)

# Parent splitter: large chunks for context
parent_splitter = RecursiveCharacterTextSplitter(
    chunk_size=2000,
    chunk_overlap=200,
)

# Child splitter: small chunks for precise retrieval
child_splitter = RecursiveCharacterTextSplitter(
    chunk_size=400,
    chunk_overlap=50,
)


def chunk_and_store(filepath: str, filename: str):
    """Read a file, perform hierarchical chunking, and store in ChromaDB."""
    with open(filepath, "r", encoding="utf-8") as f:
        text = f.read()

    parent_chunks = parent_splitter.split_text(text)
    parent_ids = []
    child_ids = []
    child_documents = []
    child_metadatas = []

    for i, parent_text in enumerate(parent_chunks):
        parent_id = str(uuid.uuid4())
        parent_ids.append(parent_id)

        # Split parent into children
        children = child_splitter.split_text(parent_text)
        for j, child_text in enumerate(children):
            child_id = str(uuid.uuid4())
            child_ids.append(child_id)
            child_documents.append(child_text)
            child_metadatas.append({
                "parent_id": parent_id,
                "filename": filename,
                "parent_index": i,
                "child_index": j,
            })

    # Store parent chunks
    if parent_ids:
        parent_collection.add(
            ids=parent_ids,
            documents=parent_chunks,
            metadatas=[
                {"filename": filename, "parent_index": i}
                for i in range(len(parent_chunks))
            ],
        )

    # Store child chunks
    if child_ids:
        child_collection.add(
            ids=child_ids,
            documents=child_documents,
            metadatas=child_metadatas,
        )

    print(
        f"[Ingestion Done] {filename}: "
        f"{len(parent_ids)} parent chunks, {len(child_ids)} child chunks | "
        f"Total in ChromaDB - parents: {parent_collection.count()}, "
        f"children: {child_collection.count()}"
    )


async def consume():
    """Continuously consume jobs from the file queue."""
    logger.info("Consumer started, waiting for jobs...")
    while True:
        job = await file_queue.pop()
        try:
            logger.info(f"Processing: {job.filename}")
            await asyncio.to_thread(chunk_and_store, job.filepath, job.filename)
            logger.info(f"Done: {job.filename}")
        except Exception:
            logger.exception(f"Failed to process: {job.filename}")
        finally:
            file_queue.done()
