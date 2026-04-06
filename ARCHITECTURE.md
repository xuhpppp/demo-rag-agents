# Architecture

## Overview

A multi-agent system built with LangGraph and LangChain, using Claude on AWS Bedrock as the LLM. The orchestrator agent receives user questions and delegates to specialized sub-agents via tools.

```
User
 │
 ▼
Orchestrator Agent (app.py)
 │   Claude Sonnet 4.6 via Bedrock
 │   Decides which tool(s) to call based on the question
 │
 └──► query_synthea_database (tool)
           │
           ▼
      SQL Sub-Agent (agents/synthea_sql_agent.py)
           │   Claude Sonnet 4.6 via Bedrock
           │   Translates natural language → SQL → executes → summarizes
           │
           └──► SQLDatabaseToolkit
                     ├── sql_db_list_tables   — discover available tables
                     ├── sql_db_schema        — inspect table structure
                     ├── sql_db_query_checker — validate SQL before running
                     └── sql_db_query         — execute SQL against MySQL
                                │
                                ▼
                         Synthea MySQL Database
```

## Components

### Orchestrator (`app.py`)

- Entry point for user interaction
- Routes questions to the appropriate sub-agent tool
- Answers general questions directly without delegating
- Streams the final response token-by-token to the user

### SQL Sub-Agent (`agents/synthea_sql_agent.py`)

- Specialized agent for querying the Synthea patient database
- Follows a fixed reasoning loop: list tables → inspect schema → validate SQL → execute → summarize
- Read-only: DML statements (INSERT, UPDATE, DELETE, DROP) are prohibited by its system prompt
- Exposed via `create_sql_agent()` for import by the orchestrator, and runnable standalone via `python -m agents.synthea_sql_agent`

## Infrastructure

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| MySQL | `mysql:8.0.40` | 3306 | Primary database — stores all Synthea patient data |
| ChromaDB | `chromadb:1.5.5` | 8001 | Vector database — stores document embeddings for RAG |

Both services are defined in `docker-compose.yml` with persistent named volumes.

## Adding a New Sub-Agent

1. Create `agents/your_agent.py` with a `create_your_agent()` factory function
2. In `main.py`, wrap it as a `@tool` with a clear docstring (the orchestrator uses the docstring to decide when to call it)
3. Add the tool to the orchestrator's `tools=[...]` list
