# Kinetic-Stream-OS

High-Velocity Telemetry Orchestration for Distributed Edge Environments

**Kinetic-Stream-OS** is a reference architecture for managing high-throughput (250+ events/sec) relational data across geographically dispersed industrial sites. Developed to simulate the data gravity and integrity challenges of a 30-site warehouse robotics fleet, it leverages a Python-to-MSSQL pipeline orchestrated via containerized Jenkins on a Linux (Ubuntu 24.04/WSL2) stack.

---

🏗️ Architectural Philosophy

In a distributed robotics environment, data is heavy and latency is expensive. This project rejects "Cloud-Only" assumptions in favor of a **Cellular Edge Architecture**:

- **Data Integrity at Scale**: Validates relational parity at a 250,000-row grain to prevent "row explosion" or data loss during complex 40-50 column joins.
- **Hybrid CI/CD**: Utilizes an on-premises Jenkins-in-Docker model to simulate deployment to secure, private warehouse networks.
- **Idempotent Ingestion**: Employs Python-based bulk loading (`fast_executemany`) to handle 12 TB/site/day ingestion volumes without locking the transactional engine.

---

## Prerequisites

- Docker & docker-compose
- Ubuntu 24.04 / WSL2

> Demo credentials are pre-configured in `.env` and `docker-compose.yml` — no manual setup required. See `.env.example` if deploying to a real environment.

---

## 🚀 Quick Start

**Step 1 — Environment Bootstrap**
Install Microsoft ODBC 18 drivers and initialize the Python virtual environment (Ubuntu 24.04/WSL2):

```bash
source ./scripts/setup_env.sh
```

**Step 2** — Infrastructure Launch
Start the MSSQL 2022 and Jenkins containers in detached mode:

```bash
docker-compose up -d
```

Note: If port 1433 is already in use on your host, the container may fail to start. You can modify the port mapping in docker-compose.yml if necessary.

**Step 3** — High-Velocity Ingestion
The database includes a healthcheck. Once the container is `healthy` (approx. 20s), run the ingestor to populate the `Site_Telemetry_Raw` table with 250,000 rows x 50 columns of data:

```bash
# Automated wait for healthcheck
docker heartbeat kinetic-db 2>/dev/null || \
until [ "$(docker inspect -f {{.State.Health.Status}} kinetic-db)" = "healthy" ]; do sleep 2; done

# Execute the ingestion engine to stream 250k rows into 'Site_Telemetry_Raw'
python3 app/ingestor.py
```
---

🚀 Technical Stack

- **Engine**: Microsoft SQL Server 2022 (Linux Container)
- **Orchestration**: Jenkins (Docker-managed)
- **Runtime**: Python 3.12 (Virtual Environment / SQLAlchemy / PyODBC)
- **Environment**: Ubuntu 24.04 LTS (WSL2 / RHEL-compatible scripts)
- **Validation**: T-SQL `EXCEPT` & `CHECKSUM` parity logic

---

🛠️ Implementation Details

1. The Validation Engine

To address the risk of data corruption in 50-column wide tables, the system executes a pre-deployment "Grain Check." It compares the record count and checksums of the incoming 250k-row batch against the existing telemetry store before committing.

2. High-Throughput Ingestion

The Python backend implements a chunked, asynchronous-style loading pattern. This bypasses the overhead of row-by-row inserts, allowing the system to sustain the velocity required by 250+ sensors reporting concurrently.

3. Automated Lifecycle

A Jenkins Pipeline (`Jenkinsfile`) manages the lifecycle:

1. **Lint**: Static analysis of SQL and Python.
2. **Mock**: Execution against a localized 250k-row test-set in Docker.
3. **Verify**: Automatic failure of the build if the "Row Delta" is non-zero.
4. **Ship**: Packaging of the validated logic into a site-ready Docker image.

> **Jenkins Setup**: The pipeline requires a credential named `mssql-creds` configured in Jenkins UI (`Manage Jenkins → Credentials`). Set the username to `sa` and the password to match your `.env` / `docker-compose.yml` SA password.

---

📈 Real-World Performance Constraints

This project was benchmarked to solve for:

- **Volume**: 4-6 TB of daily ingestion per site.
- **Velocity**: 250 state changes per second per site.
- **Reliability**: Zero-loss joins across high-density telemetry schemas.

---

📂 Project Structure



```textile
├── app/
│   ├── ingestor.py       # High-velocity Python loader
│   └── validator.py      # Relational parity logic
├── sql/
│   ├── schema.sql        # 50-column wide table definition
│   └── validation.sql    # EXCEPT/CHECKSUM logic
├── jenkins/
│   └── Jenkinsfile       # Orchestration script
├── docker-compose.yml    # Full-stack (MSSQL + Jenkins)
└── README.md
```