import os

import consumer

from dotenv import load_dotenv
from langchain_community.utilities import SQLDatabase
from langchain_community.agent_toolkits import SQLDatabaseToolkit
from langchain_core.tools import tool
from langchain.agents import create_agent


load_dotenv()


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


def create_single_agent(model, checkpointer=None):

    db = SQLDatabase.from_uri(
        f"mysql+pymysql://{os.getenv('DB_USER')}:{os.getenv('DB_PASSWORD')}@{os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}/{os.getenv('DB_NAME')}"
    )
    toolkit = SQLDatabaseToolkit(db=db, llm=model)
    sql_tools = toolkit.get_tools()

    tools = sql_tools + [search_medical_guidelines]

    system_prompt = """You are a helpful healthcare data assistant with access to two types of tools:

**SQL tools** — Use these to query the Synthea patient database for actual patient data,
conditions, medications, encounters, and healthcare statistics.
- sql_db_list_tables: discover available tables
- sql_db_schema: inspect table structure
- sql_db_query_checker: validate SQL before running
- sql_db_query: execute SQL against the database

**search_medical_guidelines** — Search uploaded medical guidelines and protocols for
clinical recommendations, treatment standards, and healthcare policies.

When answering questions about patient data:
- ALWAYS start by listing tables, then inspect relevant schemas before writing SQL.
- Double check your query before executing it. If you get an error, rewrite and retry.
- DO NOT make any DML statements (INSERT, UPDATE, DELETE, DROP etc.).
- Unless the user specifies a number, limit queries to at most 5 results.

When answering questions about guidelines:
- ALWAYS use search_medical_guidelines to find relevant information before answering.
- Include inline citations using the format [source_filename] after each claim.
- Include a "Sources" section at the end listing all cited documents.

Use BOTH SQL tools and search_medical_guidelines when the user wants to compare
guidelines with actual patient data.

For general questions not related to the database or guidelines, answer directly.

When presenting tabular data, you MUST use proper markdown table syntax with a header
separator row. Example:

| Column A | Column B |
|----------|----------|
| value 1  | value 2  |

Never use pipe characters for anything other than markdown tables.""".format(
        dialect=db.dialect,
    )

    return create_agent(
        debug=True,
        model=model,
        tools=tools,
        system_prompt=system_prompt,
        checkpointer=checkpointer,
    )
