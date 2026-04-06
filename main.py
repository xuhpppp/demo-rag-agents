import os

from dotenv import load_dotenv
from langchain_aws import ChatBedrock
from langchain_core.tools import tool
from langchain.agents import create_agent

from agents.synthea_sql_agent import create_sql_agent

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

For general questions not related to the database, answer directly.""",
)

# Run the orchestrator
question = input("Ask a question: ")

for chunk, metadata in orchestrator.stream(
    {"messages": [{"role": "user", "content": question}]},
    stream_mode="messages",
):
    if metadata["langgraph_node"] == "model" and isinstance(chunk.content, list):
        for block in chunk.content:
            if block.get("type") == "text":
                print(block["text"], end="", flush=True)
print()
