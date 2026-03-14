# Shifting to Cloud & Production Grade

While the current Docker-based setup is perfect for development and local testing, a professional Public Health surveillance system needs a high-availability cloud architecture.

---

## 1. Architecture Transition (Local vs. Cloud)

| Component | Local (Docker) | Cloud (AWS/GCP/Azure) |
| :--- | :--- | :--- |
| **Database** | Docker Container (`db`) | **Managed RDS** (PostgreSQL) with Multi-AZ. |
| **Storage** | Local Folders | **S3 / Cloud Storage** for raw CSV drops. |
| **Compute** | Shared `Dockerfile` | **ECS Fargate** or **Kubernetes (EKS)**. |
| **Automation** | Self-hosted n8n | **Managed n8n** or **AWS Step Functions**. |
| **Dashboard** | Streamlit Service | **Streamlit on App Runner** or Private EC2. |

---

## 2. Production-Grade Enhancements

### **A. Serverless Data Ingestion**
Instead of manually dropping CSVs into a folder, we can use an **S3 Event Trigger**:
1.  New CSV arrives in `s3://covid-data-raw/`.
2.  Trigger an **AWS Lambda** function.
3.  The Lambda function calls the `app` container service to run the ETL immediately.

### **B. Enhanced Security**
*   **Secrets Management**: Move database passwords from `.env` to **AWS Secrets Manager**.
*   **VPC Isolation**: Place the Database and Orchestrator in a Private Subnet, exposing only the Streamlit UI via a Load Balancer.
*   **IAM Roles**: Use granular IAM roles instead of root keys for service-to-service communication.

### **C. Observability & Monitoring**
*   **CloudWatch Logs**: Centralize logs from all containers to detect ingestion failures.
*   **Health Checks**: Implement `/health` endpoints in the Python apps so the Load Balancer can automatically restart unhealthy containers.
*   **Alerting**: Add **SNS (Simple Notification Service)** to notify the technical team if the ETL pipeline fails.

---

## 3. Handling Big Data (Scalability)

If the dataset grows from 40k rows to 40 million:
1.  **Postgres Partitioning**: Partition the `covid_summary_clean` table by `year` or `state` to maintain query speed.
2.  **dbt (data build tool)**: Replace the `main.py` SQL executor with **dbt**. It provides built-in testing, documentation, and lineage for complex enterprise pipelines.
3.  **Read Replicas**: Use a Read Replica for the Streamlit dashboard so that heavy analytical queries don't slow down the ingestion process.

---

## 4. Deployment Roadmap
1.  **Phase 1**: Provision a managed PostgreSQL instance.
2.  **Phase 2**: Containerize and push images to a Private Registry (ECR).
3.  **Phase 3**: Deploy services using an Orchestrator (Fargate/K8s).
4.  **Phase 4**: Configure SSL certificates and a custom domain for the Executive Portal.
