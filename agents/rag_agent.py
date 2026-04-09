import os
import consumer

from langchain_core.tools import tool
from langchain.agents import create_agent


@tool
def search_medical_guidelines(query: str) -> str:
    """Search the medical guidelines knowledge base for relevant information.
    Use this tool to find guidelines, protocols, and recommendations from
    uploaded medical documents stored in the vector database.
    """
    results = consumer.vector_store.similarity_search_with_relevance_scores(
        query=query, k=3, score_threshold=0.3
    )
    if not results:
        return "No relevant guidelines found for this query."

    formatted = []
    for i, (doc, score) in enumerate(results, 1):
        source = os.path.basename(doc.metadata.get("source", "unknown"))
        formatted.append(
            f"[{i}] (relevance: {score:.2f}, source: {source})\n{doc.page_content}"
        )
    return "\n\n---\n\n".join(formatted)


def create_rag_agent(model):

    system_prompt = """You are a medical guidelines assistant. Your role is to answer
questions about healthcare guidelines, protocols, and recommendations using the
medical documents stored in the knowledge base.

ALWAYS use the search_medical_guidelines tool to find relevant information before
answering. Do not make up medical information — only use what the documents provide.

When answering:
- You MUST include inline citations for every claim. Use the format [source_filename]
  after each statement, e.g. "HbA1c targets should be below 7% [糖尿病診療ガイドライン.txt]".
- At the end of your answer, include a "Sources" section listing all cited documents.
- If the retrieved documents do not contain enough information to answer the question,
  say so clearly rather than guessing.
- Present information clearly and accurately.
- You may answer in the same language as the user's question."""

    return create_agent(
        debug=True,
        model=model,
        tools=[search_medical_guidelines],
        system_prompt=system_prompt,
    )
