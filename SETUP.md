# Project Setup Guide

## Prerequisites

- **Docker Desktop** installed and running
- **Python 3.10+** installed

## 1. Clone and enter the project

```bash
cd demo_rag_agents
```

## 2. Generate Synthea patient data

This step generates ~1,000 synthetic patient records for New York using [Synthea](https://github.com/synthetichealth/synthea). It runs inside a disposable Docker container with Java 17.

```bash
# Linux / macOS / Git Bash
bash script/generate_synthea_data.sh

# Windows (PowerShell)
.\script\generate_synthea_data.ps1
```

The script will:
1. Spin up a temporary Java 17 container
2. Clone and build Synthea from source
3. Generate 1,000 patients with `./run_synthea -p 1000 'New York'`
4. Copy the 18 CSV files into the `output/` directory
5. Remove the container

> This may take several minutes depending on your machine and network speed.

## 3. Configure environment variables

Copy the example and fill in your AWS credentials:

```bash
cp .env.example .env
```

Required variables in `.env`:

| Variable | Description |
|----------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS credentials for Bedrock (Claude + Cohere embeddings) |
| `AWS_SECRET_ACCESS_KEY` | AWS credentials for Bedrock |
| `AWS_REGION` | AWS region (e.g. `ap-northeast-1`) |

The remaining variables (`DB_*`, `CHROMA_*`, `LANGFUSE_*`) have defaults that match the Docker Compose services.

## 4. Start all services with Docker

```bash
docker compose up -d
```

This starts the following containers:

**MySQL 8.0** (`demo_rag_mysql`):

| Setting | Value |
|---------|-------|
| Host | `localhost` (or `mysql` from other containers) |
| Port | `3306` |
| Root password | `rootpassword` |
| App user | `rag_user` |
| App password | `rag_password` |
| Default database | `rag_db` |

**ChromaDB** (vector database for RAG):

| Setting | Value |
|---------|-------|
| Host | `localhost` (or `chromadb` from other containers) |
| Port | `8001` |
| Collection | `example_collection` |
| Distance metric | `cosine` |

**Webapp** (`demo_rag_webapp`):

| Setting | Value |
|---------|-------|
| URL | `http://localhost:8000` |
| Image | Built from `Dockerfile` |

**Langfuse** (agent tracing UI):

| Setting | Value |
|---------|-------|
| URL | `http://localhost:3000` |
| Login | `admin@local.dev` / `admin123` |

Langfuse also starts PostgreSQL, ClickHouse, Redis, and MinIO as backing services. Buckets in MinIO are auto-created by the `langfuse-minio-init` service.

> First startup may take a few minutes while images are pulled and Langfuse runs its migrations.

## 5. Create the database schema and load data

This is a one-time step that runs from the host. You need Python and `pymysql` installed locally:

```bash
pip install pymysql
python script/load_data.py
```

This script will:
1. Run `script/init_db.sql` to create the `synthea_db` database and all 18 tables
2. Load CSV files from `output/` into each table in the correct order (respecting foreign keys)
3. Grant `rag_user` full access to `synthea_db`

Expected output:

```
Creating schema...
Loading organizations...
  organizations: 1458 rows
Loading payers...
  payers: 10 rows
Loading patients...
  patients: 1195 rows
Loading providers...
  providers: 1458 rows
Loading encounters...
  encounters: 78621 rows
...
Loading claims_transactions...
  claims_transactions: 1182428 rows

Done! All data loaded into synthea_db.
```

Total: ~3 million rows across 18 tables.

## 7. Verify the database

Connect to the database and run a quick check:

```python
import pymysql

conn = pymysql.connect(
    host="127.0.0.1",
    port=3306,
    user="rag_user",
    password="rag_password",
    database="synthea_db",
)
cur = conn.cursor()
cur.execute("SELECT COUNT(*) FROM patients")
print(cur.fetchone())  # (1195,)
conn.close()
```

## 8. Upload RAG documents

Navigate to `http://localhost:8000/upload` and upload the `.txt` files from `rag_documents/`. These will be chunked, embedded, and stored in ChromaDB automatically via the background consumer.

## Project Structure

```
demo_rag_agents/
├── app.py                    # FastAPI server, orchestrator agent
├── consumer.py               # Background document ingestion (queue → chunk → embed → ChromaDB)
├── queue_manager.py          # Async file job queue
├── agents/
│   ├── synthea_sql_agent.py  # SQL sub-agent for querying patient data
│   └── rag_agent.py          # RAG sub-agent for searching medical guidelines
├── rag_documents/            # Japanese medical guideline .txt files for RAG
├── static/                   # Chat and upload web UI
├── Dockerfile                # Webapp container image definition
├── .dockerignore             # Files excluded from Docker build context
├── docker-compose.yml        # All services (webapp, MySQL, ChromaDB, Langfuse stack)
├── clickhouse-config.xml     # ClickHouse Keeper config for single-node Langfuse
├── script/
│   ├── init_db.sql           # Database schema (18 tables)
│   └── load_data.py          # CSV → MySQL loader script
├── output/                   # Synthea-generated CSV data files
│   ├── patients.csv
│   ├── encounters.csv
│   ├── observations.csv
│   └── ... (18 CSV files)
├── requirements.txt          # Python dependencies
├── ARCHITECTURE.md           # System architecture documentation
├── SCHEMA.md                 # Database schema documentation
├── database_structure.md     # Detailed schema documentation (Japanese)
├── SETUP.md                  # This file
└── .venv/                    # Python virtual environment
```

## Teardown

To stop all containers (data is preserved in Docker volumes):

```bash
docker compose down
```

To also delete all stored data (MySQL, ChromaDB, Langfuse):

```bash
docker compose down -v
```
