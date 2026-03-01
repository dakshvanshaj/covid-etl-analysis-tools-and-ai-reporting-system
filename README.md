# 🚀 COVID-19 Analysis & AI Early Warning System

## 📌 Project Overview
This project implements an end-to-end **Data Analysis** to analyze India’s COVID-19 pandemic data. Adopting a **Medallion Architecture**, it combines robust Data Engineering (SQL ETL), Advanced Analytics (Excel/Power BI), and GenAI Automation (n8n) to provide both historical insights and proactive early-warning alerts for public health stakeholders.

---

## 📌 Key Objectives
1.  **ETL**: Consolidate disparate datasets (Cases, Vaccination, Testing) into a single source of truth.
2.  **Analytics**: Visualize trends, vaccination progress, and state-wise impact.
3.  **Automation**: Operationalize insights via AI-driven daily reports and risk alerts.

## 🏗️ System Architecture
The system operates on a centralized data warehouse that feeds both passive and active monitoring layers.

1.  **Data Warehouse (PostgreSQL)**: Single source of truth storing Bronze, Silver, and Gold data layers.
2.  **Analytics Layer (Excel & Power BI)**: Passive monitoring, exploratory analysis, and interactive dashboards.
3.  **Automation Layer (n8n + GenAI)**: Active monitoring that triggers daily risk assessments and generates LLM-powered situation reports.

---

## ⚙️ The Pipeline: Phase-by-Phase

### Phase 1: SQL ETL (Extract, Transform, Load)
We utilized a **Medallion Architecture** to process raw CSVs (`covid_19_india.csv`, `covid_vaccine_statewise.csv`, `StatewiseTestingDetails.csv`) into a production-grade warehouse.

*   **Bronze Layer (Ingestion)**:
    *   Created staging tables with `TEXT` data types to prevent ingestion failures caused by inconsistent CSV headers or formatting.
    *   Implemented defensive SQL to filter out metadata rows before processing.
*   **Silver Layer (Standardization)**:
    *   **Data Hygiene**: Used `NULLIF` and `COALESCE` to handle inconsistent missing values (dashes, empty strings).
    *   **Date Parsing**: Implemented conditional `CASE` logic to parse heterogeneous date formats (e.g., `dd/mm/yyyy` vs `yyyy-mm-dd`) into a standard SQL `DATE` type.
*   **Gold Layer (Feature Engineering)**:
    *   **Imputation**: Applied a forward-fill strategy using `MAX() OVER (PARTITION BY state)` to handle sparse reporting days for vaccination/testing data.
    *   **Metrics**: Engineered `Daily_New_Cases` using `LAG()` window functions and calculated `Positivity Rate` and `Case Fatality Rate (CFR)`.
    *   **Deduplication**: Enforced data grain integrity (1 row per state per day) using `ROW_NUMBER()` to remove duplicate entries.
    *   **Persistence**: Added `postgres_etl` backup to ensure database recoverability.

### Phase 2: Advanced Analytics (Excel)
*   **Forecasting**: Deployed Exponential Smoothing (ETS) algorithms to project case trajectories 30 days into the future with 95% confidence intervals.
*   **Risk Stratification**: Built dynamic arrays to categorize states into High/Medium/Low risk based on active cases and mortality trends.
*   **Anomaly Detection**: Identified "Administrative Seasonality" where case reporting consistently dipped on Tuesdays due to weekend lags.
*   **Excel Dashboard**:
![alt text](images/excel_dashboard.png)

### Phase 3: Power BI dashboard
![alt text](images/powerbi_dashboard.png)
![alt text](images/powerbi_dashboard_2.png)

### Phase 3: AI Automation (n8n + GenAI)
Designed two automated workflows to bridge the gap between data and decision-makers.

![alt text](images/WorkFlow1.png)
#### Workflow 1: Daily Situation Report
*   **Goal**: Routine executive briefing.
*   **Process**: Aggregates national/state data → Generates AI summary via OpenAI → Emails stakeholders.


![alt text](images/n8n_covid_alert.png)

#### Workflow 2: Early Warning Alert System
*   **Goal**: Proactive risk detection.
*   **Logic**: Triggers if:
    1.  Cases rise for 3 consecutive days.
    2.  Positivity Rate > 10%.
    3.  Vaccination growth slows while cases rise.
*   **Action**: GenAI explains *why* the trend is concerning and suggests immediate containment actions.

---

## 📂 Project Structure

```text
├── data/               # Raw CSV datasets (Bronze)
├── sql/                # ETL scripts & postgres_etl backup
├── excel/              # EDA workbooks and forecasting models
├── powerbi/            # Interactive .pbix dashboards
├── n8n/                # Automation workflow JSONs (Report & Alert)
├── images/             # Project screenshots
├── docs/               # Detailed reports and visual assets
└── README.md           # Master documentation
