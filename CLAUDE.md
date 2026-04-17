# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Healthcare data system combining RAG (medical guidelines) with SQL querying (synthetic patient data) using LangGraph/LangChain agents on AWS Bedrock. Users choose between two agent modes via the chat UI: **orchestrator** (multi-agent delegation) or **single agent** (all tools in one agent).

## Commands

```bash
# Start all services (MySQL, ChromaDB, Langfuse, webapp)
docker compose up -d

# Rebuild webapp after code changes
docker compose up -d --build webapp

# Generate synthetic patient data (one-time, takes several minutes)
bash script/generate_synthea_data.sh        # Linux/macOS/Git Bash
.\script\generate_synthea_data.ps1          # PowerShell

# Load patient data into MySQL (one-time, run from host after docker compose up)
pip install pymysql
python script/load_data.py

# Run webapp locally (outside Docker, requires .env configured)
pip install -r requirements.txt
uvicorn app:app --host 0.0.0.0 --port 8000

# Teardown (preserving data)
docker compose down
# Teardown (delete all data)
docker compose down -v
```

No test suite or linter is configured.

## Architecture

### Two Agent Modes

Both modes are fronted by a **topic guardrail** (`guardrail.py`) — a lightweight Haiku classifier that rejects off-topic queries before any agent runs.

**Orchestrator mode** (`app.py` builds it via `_build_orchestrator()`):
- Sonnet orchestrator with two tools: `query_synthea_database` and `search_medical_guidelines`
- Each tool delegates to an independent sub-agent (SQL sub-agent uses Sonnet, RAG sub-agent uses Haiku)
- Sub-agents are created via factory functions in `agents/`

**Single agent mode** (`agents/single_agent.py`):
- One Sonnet agent with all 5 tools directly (4 SQL toolkit tools + RAG search)
- Fewer LLM round-trips, lower latency

### Key Data Flow

- **Chat**: `POST /chat` -> guardrail check -> agent stream (SSE) -> token-by-token response
- **Upload**: `POST /upload` -> `FileQueue` -> background `consumer.py` -> chunk with `RecursiveCharacterTextSplitter` (1000 chars, 200 overlap) -> embed with Cohere v4 -> store in ChromaDB
- **Memory**: In-memory `MemorySaver` with TTL-based cleanup (5 min idle per thread, swept every 30s)

### Agent Creation Pattern

All agents use factory functions: `create_sql_agent()`, `create_rag_agent()`, `create_single_agent()`. Agents are lazily created and cached by provider+type key in `_agent_cache`. To add a new sub-agent: create a factory in `agents/`, wrap it as a `@tool` in `app.py`, and add it to the orchestrator's tools list and system prompt.

### Model Configuration

- `get_bedrock_model()` returns Sonnet 4.6 by default, Haiku 4.5 with `role="light"`
- `get_openai_model()` returns GPT model as an alternative provider
- Provider is selected per-request via the `provider` field in `ChatRequest`

## Services (docker-compose.yml)

| Port | Service | Notes |
|------|---------|-------|
| 8000 | Webapp (FastAPI) | Built from Dockerfile |
| 3306 | MySQL 8.0 | Synthea patient data (18 tables, ~3M rows) |
| 8001 | ChromaDB | Vector store for RAG (cosine distance) |
| 3000 | Langfuse | Tracing UI (login: admin@local.dev / admin123) |

Langfuse depends on PostgreSQL (5432), ClickHouse (8123), Redis (6379), and MinIO (9090) — all defined in docker-compose.yml.

## Environment Variables

AWS credentials are required for Bedrock (Claude + Cohere embeddings): `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`. All other vars (`DB_*`, `CHROMA_*`, `LANGFUSE_*`) have defaults matching the Docker Compose services. Inside Docker, the webapp connects to services by container hostname (e.g., `mysql`, `chromadb`); locally, use `localhost`.
