# Architecture

## Overview

A healthcare data system built with LangGraph and LangChain, using Claude on AWS Bedrock as the LLM. Users choose between two agent modes at the start of each chat session:

- **Orchestrator mode** — A multi-agent architecture where an orchestrator delegates to specialized sub-agents (SQL and RAG) via tools. Better separation of concerns; each sub-agent has a focused prompt.
- **Single agent mode** — One agent with all tools (SQL toolkit + RAG search) directly. Fewer LLM round-trips, lower latency.

Both modes combine SQL querying of patient data with RAG search over medical guidelines.

### Orchestrator Mode

```
User → selects "Orchestrator" in chat UI
 │
 ▼
Topic Guardrail (guardrail.py)
 │   Claude Haiku 4.5 via Bedrock (lightweight classifier)
 │   Rejects off-topic questions before they reach any agent
 │
 ▼ (on-topic only)
Orchestrator Agent (app.py)
 │   Claude Sonnet 4.6 via Bedrock
 │   Decides which tool(s) to call based on the question
 │
 ├──► query_synthea_database (tool)
 │         │
 │         ▼
 │    SQL Sub-Agent (agents/synthea_sql_agent.py)
 │         │   Claude Sonnet 4.6 via Bedrock
 │         │   Translates natural language → SQL → executes → summarizes
 │         │
 │         └──► SQLDatabaseToolkit
 │                   ├── sql_db_list_tables   — discover available tables
 │                   ├── sql_db_schema        — inspect table structure
 │                   ├── sql_db_query_checker — validate SQL before running
 │                   └── sql_db_query         — execute SQL against MySQL
 │                              │
 │                              ▼
 │                       Synthea MySQL Database
 │
 └──► search_medical_guidelines (tool)
           │
           ▼
      RAG Sub-Agent (agents/rag_agent.py)
           │   Claude Haiku 4.5 via Bedrock
           │   Retrieves relevant guidelines → synthesizes answer with citations
           │
           └──► search_medical_guidelines (internal tool)
                         │
                         ▼
                  ChromaDB Vector Store
                  (cosine similarity, score threshold 0.3)
```

### Single Agent Mode

```
User → selects "Single Agent" in chat UI
 │
 ▼
Topic Guardrail (guardrail.py)
 │   Claude Haiku 4.5 via Bedrock (lightweight classifier)
 │   Rejects off-topic questions before they reach any agent
 │
 ▼ (on-topic only)
Single Agent (agents/single_agent.py)
 │   Claude Sonnet 4.6 via Bedrock
 │   Has direct access to all tools — no sub-agents
 │
 ├──► SQLDatabaseToolkit
 │         ├── sql_db_list_tables
 │         ├── sql_db_schema
 │         ├── sql_db_query_checker
 │         └── sql_db_query ──► Synthea MySQL Database
 │
 └──► search_medical_guidelines ──► ChromaDB Vector Store
```

### Document Ingestion Pipeline

```
User uploads .txt via /upload
 │
 ▼
FileQueue (queue_manager.py)
 │   Async queue of FileJob objects
 │
 ▼
Consumer (consumer.py)
 │   Background task started on app startup
 │   Loads .txt → splits into chunks (1000 chars, 200 overlap)
 │   Embeds with Cohere Embed v4
 │
 ▼
ChromaDB (example_collection)
 │   Cosine distance metric
 │   Persistent via HTTP client → Docker container
```

## Components

### App (`app.py`)

- Entry point for user interaction via FastAPI
- Initializes both agent modes (orchestrator + single) at startup
- The `/chat` endpoint runs a **topic guardrail** before routing to any agent — off-topic messages are rejected immediately
- The `/chat` endpoint accepts an `agent` field (`"orchestrator"` or `"single"`) to select which mode handles the request
- Streams the final response token-by-token to the user via SSE
- All agent invocations are traced via Langfuse `CallbackHandler` for observability

### Topic Guardrail (`guardrail.py`)

- Lightweight LLM-based classifier that runs before every agent invocation
- Uses the light model (Haiku) to classify whether a user message is medical/healthcare-related
- On-topic messages (patient data, medications, guidelines, procedures, insurance, etc.) pass through to the agent
- Off-topic messages (coding, sports, recipes, prompt injection attempts, etc.) receive a polite refusal without invoking any agent

### Orchestrator Agent (`app.py`)

- Routes questions to the appropriate sub-agent tool(s)
- Can call both tools in a single turn when the user wants to compare guidelines with actual patient data
- Preserves inline citations from the RAG agent in its final response

### Single Agent (`agents/single_agent.py`)

- One agent with all 5 tools: SQLDatabaseToolkit (4 tools) + `search_medical_guidelines`
- Fewer LLM round-trips than orchestrator mode (no routing/synthesis overhead)
- Combined system prompt covers both SQL and RAG behaviors
- Exposed via `create_single_agent()` factory function

### SQL Sub-Agent (`agents/synthea_sql_agent.py`)

- Used by orchestrator mode only
- Specialized agent for querying the Synthea patient database
- Follows a fixed reasoning loop: list tables → inspect schema → validate SQL → execute → summarize
- Read-only: DML statements (INSERT, UPDATE, DELETE, DROP) are prohibited by its system prompt
- Exposed via `create_sql_agent()` factory function

### RAG Sub-Agent (`agents/rag_agent.py`)

- Used by orchestrator mode only
- Specialized agent for answering questions using uploaded medical guideline documents
- Searches ChromaDB via cosine similarity with a relevance score threshold
- Synthesizes answers from retrieved document chunks with inline citations (e.g. `[filename.txt]`)
- Includes a "Sources" section at the end of each response
- Exposed via `create_rag_agent()` factory function

### Document Consumer (`consumer.py`)

- Background async task that continuously processes the file upload queue
- Loads `.txt` files, splits them into chunks using `RecursiveCharacterTextSplitter`
- Embeds chunks with Cohere Embed v4 and stores them in ChromaDB
- The `vector_store` object is shared with the RAG agent for retrieval

## Infrastructure

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| Webapp | `Dockerfile` (build) | 8000 | FastAPI application — orchestrator, sub-agents, file upload |
| MySQL | `mysql:8.0.40` | 3306 | Primary database — stores all Synthea patient data |
| ChromaDB | `chromadb/chroma:1.5.5` | 8001 | Vector database — stores document embeddings for RAG (cosine distance) |
| Langfuse Web | `langfuse/langfuse:3` | 3000 | Tracing UI — visualize agent traces, LLM calls, and tool usage |
| Langfuse Worker | `langfuse/langfuse-worker:3` | — | Background worker — processes trace ingestion and analytics |
| ClickHouse | `clickhouse/clickhouse-server` | 8123 | Analytics database for Langfuse (with built-in Keeper for single-node replication) |
| MinIO | `minio/minio` | 9090 | S3-compatible blob storage for Langfuse trace data |
| PostgreSQL | `postgres:17` | 5432 | Metadata database for Langfuse |
| Redis | `redis:7` | 6379 | Queue backend for Langfuse worker |

All services are defined in `docker-compose.yml` with persistent named volumes. ClickHouse requires a custom config (`clickhouse-config.xml`) mounted into the container to enable the built-in Keeper for single-node replication.

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/` | Serves the chat UI |
| `GET` | `/upload` | Serves the document upload page |
| `POST` | `/upload` | Uploads a `.txt` file and enqueues it for embedding |
| `POST` | `/chat` | Streams an SSE response from the selected agent (`agent`: `"orchestrator"` or `"single"`) |
| `DELETE` | `/vectors` | Clears the ChromaDB collection and recreates it |

## Adding a New Sub-Agent

1. Create `agents/your_agent.py` with a `create_your_agent()` factory function
2. In `app.py`, import it and wrap as a `@tool` with a clear docstring (the orchestrator uses the docstring to decide when to call it)
3. Add the tool to the orchestrator's `tools=[...]` list
4. Update the orchestrator's system prompt to describe when to use the new tool
