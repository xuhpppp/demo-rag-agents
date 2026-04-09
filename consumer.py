import asyncio
import os

import chromadb
from langchain_chroma import Chroma
from langchain_aws import BedrockEmbeddings
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import TextLoader

from dotenv import load_dotenv

from queue_manager import file_queue

load_dotenv()


# Initialize Bedrock embeddings and ChromaDB client
embeddings = BedrockEmbeddings(
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
    aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
    model_id="cohere.embed-v4:0",
    region_name=os.getenv("AWS_REGION"),
)

chroma_client = chromadb.HttpClient(
    host=os.getenv("CHROMA_HOST", "localhost"),
    port=int(os.getenv("CHROMA_PORT", "8001")),
)

vector_store = Chroma(
    client=chroma_client,
    collection_name="example_collection",
    embedding_function=embeddings,
    collection_metadata={"hnsw:space": "cosine"},
)


def load_document(file_path: str) -> str:
    """
        Load txt documents from the specified directory.
        Returns:
        List of Document objects: Loaded txt documents represented as Langchain Document objects.
    """
    # Initialize txt loader with specified path
    loader = TextLoader(file_path, encoding="utf-8")

    chunks = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200).split_documents(loader.load())
    vector_store.add_documents(chunks)
    print(f"Added {len(chunks)} chunks to ChromaDB collection.")

async def consume():
    """Continuously consume jobs from the file queue."""
    print("Consumer started, waiting for jobs...")
    while True:
        job = await file_queue.pop()
        try:
            print(f"Processing: {job.filename}")
            await asyncio.to_thread(load_document, job.filepath)
            print(f"Done: {job.filename}")
        except Exception as e:
            print(f"Failed to process: {job.filename} - {e}")
        finally:
            file_queue.done()
