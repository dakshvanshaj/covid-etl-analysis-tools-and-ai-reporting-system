# Infrastructure: Docker & Orchestration

The system is fully containerized using **Docker** and **Docker Compose**. This ensures that the environment is identical whether you are running it on a local laptop or a production server.

---

## 1. The Shared Environment: `Dockerfile`

The main application service uses a optimized Python environment to ensure dependency parity and performance.

### **Key Features**:
*   **Base Image**: `python:3.14-slim` for a lightweight but robust foundation.
*   **Package Manager**: Uses **uv** (high-performance Python package installer) to sync dependencies from `uv.lock`.
*   **System Dependencies**: Installs `libpq-dev` and `build-essential` to support the PostgreSQL driver (`psycopg2`).
*   **Entrypoint**: Uses a custom `entrypoint.sh` to handle the "Wait-for-Postgres" logic before starting the application.

---

## 2. Service Orchestration: `compose.yaml`

The `compose.yaml` file defines 4 interconnected services. All sensitive credentials are now injected via the `.env` file for security.

| Service | Image | Role |
| :--- | :--- | :--- |
| **`db`** | `postgres:18.1` | The persistent data warehouse (PostgreSQL). |
| **`pgadmin`** | `dpage/pgadmin4` | Web-based database management UI. |
| **`n8n`** | `n8nio/n8n` | The automation engine for alerts and feedback. |
| **`app`** | `(Custom Build)` | The Streamlit executive portal and analysis engine. |

---

## 3. Credential Management (`.env`)

The project uses a `.env` file to manage all secrets. **Never commit this file to version control.**

**Required Variables**:
- `DB_USER` / `DB_PASSWORD`: Database credentials.
- `DB_NAME`: Defaults to `postgres`.
- `PGADMIN_DEFAULT_EMAIL` / `PGADMIN_DEFAULT_PASSWORD`: Credentials for the pgAdmin web UI.

---

## 4. Data Persistence & Portability

The system uses named Docker volumes to ensure your data survives container restarts and deletions.

### **Self-Healing Volumes**:
The volumes are configured to be "portable." If you are a new user, Docker will create them automatically. If you have existing volumes (e.g., `data_stack_pg_data`), Docker will automatically re-attach to them.

1.  `data_stack_pg_data`: Stores the actual Postgres database files.
2.  `data_stack_pgadmin_data`: Stores your pgAdmin configurations.
3.  `n8n_data`: Stores your n8n workflows and credentials.

---

## 5. Manual n8n Workflow Setup

Since n8n stores workflows in its own internal database, you must manually import the logic after the first launch.

### **Step-by-Step Import**:
1.  Open n8n at `http://localhost:5678`.
2.  Create your account (first-time setup).
3.  Click on **Workflows** → **Add Workflow** → **Import from File**.
4.  Select `n8n_workflows/Refined_Alert_System.json`.
5.  **Configure Credentials**:
    *   **Postgres Node**: Use the values from your `.env` (Host: `db`, Port: `5432`).
    *   **Gemini Node**: Add your Google AI API Key.
6.  **Activate**: Click the **"Active"** toggle in the top-right corner.

---

## 6. Useful Commands

*   **Start everything**: `docker-compose up -d`
*   **View Logs**: `docker-compose logs -f`
*   **Shut Down (Keep Data)**: `docker-compose down`
*   **Factory Reset (Wipe All Data)**: `docker-compose down -v`
*   **Force Rebuild**: `docker-compose up --build --force-recreate`
