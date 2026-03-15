# End-to-End COVID-19 Intelligence & AI Reporting System

An integrated **Data Engineering**, **Analysis Tools** and **Generative AI** automation(n8n) platform designed to convert raw epidemic data into strategic situational awareness. This system automates the journey from messy CSVs to production-grade Postgres tables, risk evaluation tools, BI dashboard and AI driven alerts and reporting.

For a detailed breakdown of strategic goals, stakeholder mapping, and quantifiable performance metrics, refer to the **[Business Context & Impact Guide](docs/business_context.md)**.

---

## Quick Start (One-Click Setup)

### **Prerequisites**
*   **Docker Desktop** (with Docker Compose installed)
*   **Git** to clone the repository

### **1. Launch the Stack**
Clone the repository and run the following command from the project root:
```bash
docker-compose up -d
```
This will automatically launch:
*   **Postgres 18**: The persistent data warehouse.
*   **Streamlit**: The main Executive Control UI (Port 8501).
*   **n8n**: The automation engine for AI audits (Port 5678).
*   **pgAdmin**: Database management UI (Port 5050).


### **2. Activate the AI Nervous System (n8n)**
1.  Open the **Executive Portal** at `http://localhost:8501` and click **"Open n8n Workflow"** in the sidebar (or go directly to `http://localhost:5678`).
2.  Set up your n8n account (first-time only).
3.  **Import Logic**: Go to Workflows -> Add Workflow -> **Import from File**.
4.  Select `n8n_workflows/COVID-Alert-System_v2.json` from this repository.
5.  **Configure & Publish**: Add your Google Gemini API key to the AI node, click **"Execute Workflow"** to test, and then click publish.

### **3. Trigger the Intelligence Pipeline**
*   **Via UI**: In the Streamlit sidebar, click **"🔄 Trigger ETL Pipeline"**. This wipes the staging area, re-ingests the raw CSVs, and executes the Silver/Gold transformation logic.
*   **Via CLI**: Alternatively, you can run `python src/main.py --setup` if running locally.

---

## You can generate interactive dashboards using a more powerful model than defaul free to use gemma3!

## Why This is Exciting: Dynamic Intelligence
Unlike static dashboards, this system is a **living engine**. 

*   **Customizable Brains**: You can change the **System Prompts** and **SQL Data Signals** inside n8n to pivot the AI from an "Epidemiologist Persona" to a "Logistics Officer Persona."
*   **Model Agnostic**: Currently optimized for open source free to use Gemma3 , but n8n allows you to swap in any model. *Future support for local LLMs (via Ollama) is on the roadmap.*
*   **Powerful Reporting**: The more context you provide in the SQL query, the more qualitative and strategic the Gemini briefings become. Refer to `docs/ai_intelligence_setup.md` for strategic templates.
---

## 📊 Available Analysis Tools
The platform provides a "Unified Truth" across three layers:
1.  **AI Situation Room (Streamlit)**: Live, LLM-generated strategic briefings with human-in-the-loop feedback.
2.  **BI Dashboard (Power BI)**: National-level situational awareness KPI's, trend analysis with 7-day moving averages and geospatial risk maps.
3.  **Risk Evaluation Tool (Excel)**: A targeted, interactive auditing tool for stakeholders to test "what-if" threshold scenarios.

---

## Safe Power Down & Data Integrity
To stop the system without losing your database data or n8n configurations:
```bash
docker-compose down
```
**Note**: Your data is stored safely in **Docker Volumes** (`data_stack_pg_data`, `n8n_data`). It will persist even if you delete the containers. To start fresh and wipe all data, use `docker-compose down -v`.

---

## Connect & Contribute
Built by **Daksh Vanshaj**.
- **GitHub**: [End-to-End-COVID-Pipeline](https://github.com/dakshvanshaj/-End-to-End-COVID-19-Data-Analysis-AI-Early-Warning-System)
- **LinkedIn**: [Connect with me](https://www.linkedin.com/in/daksh-vanshaj-9a9650344/)
