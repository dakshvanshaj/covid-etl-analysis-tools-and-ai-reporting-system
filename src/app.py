import streamlit as st
import pandas as pd
import os
from sqlalchemy import create_engine
import time
import requests
from dotenv import load_dotenv
import streamlit.components.v1 as components

# 1. Page Config (Must be first!)
st.set_page_config(
    page_title="COVID-19 Executive Portal",
    page_icon="images/icons/covid-exclamation-line.svg",
    layout="wide",
    initial_sidebar_state="expanded",
    
)

# Load environment variables
load_dotenv()

def get_db_url():
    """Builds the connection string safely."""
    user = os.getenv("DB_USER")
    password = os.getenv("DB_PASSWORD")
    host = os.getenv("DB_HOST")
    port = os.getenv("DB_PORT")
    db = os.getenv("DB_NAME")
    
    if not all([user, password, host, port, db]):
        st.error("Missing database credentials in .env file.")
        st.stop()
        
    return f"postgresql://{user}:{password}@{host}:{port}/{db}"

# 2. Cache the SQLAlchemy engine
@st.cache_resource
def get_sql_engine():
    url = get_db_url()
    return create_engine(url)


# fetch the engine once here
engine = get_sql_engine()

# Set up UI elements
st.logo("images/logo/logo.png", icon_image="images/icons/covid-exclamation-line.svg")

st.title("COVID-19 Executive Analysis & Alerting Portal")
st.caption("Integrated ETL Pipeline, Business Intelligence, Risk Evaluation Tools and AI-Driven Surveillance System")
# st.info('Expand sidebar for control panel')
# --- SIDEBAR ---
with st.sidebar:
    st.header("Control Panel")
    st.markdown("---")
    
    # n8n Link
    st.markdown("### Automation Engine")

    st.link_button("Open n8n Workflow", "http://localhost:5678", width="stretch")
    
    st.markdown("### Sync latest data")
    # Manual System Refresh 
    if st.button("🔄 Trigger ETL Pipeline", width="stretch"):
        with st.spinner("🔄 Re-ingesting & Running Pipeline..."):
            try:
                # Import classes
                from ingest import Ingestor
                from transform import Transformer
                
                db_url = get_db_url()
                
                # Dependency Injection
                ingestor = Ingestor(db_url=db_url)
                transformer = Transformer(db_url=db_url)
                
                # Execute Pipeline
                ingestor.load_data()
                transformer.run_etl()
                
                st.success("System Sync Complete!")
                time.sleep(1)
                st.rerun()
                
            except Exception as e:
                st.error(f"Error during sync: {e}")

    st.markdown("---")
    st.subheader("📡 Infrastructure Status")
    
    # Check Database Status using the engine
    try:
        latest = pd.read_sql("SELECT MAX(date) as d FROM covid_summary_clean", engine)['d'].iloc[0]
        st.success(f"Warehouse Online \nLatest Data: {latest}")
    except Exception as e:
        print(f"Database connection failed: {e}") 
        st.error("Warehouse Offline (Run Sync)")

    st.markdown("---")
    st.subheader("Connect & Contribute")
    st.link_button("View on GitHub", "https://github.com/dakshvanshaj/-End-to-End-COVID-19-Data-Analysis-AI-Early-Warning-System", width="stretch")
    st.link_button("My LinkedIn", "https://www.linkedin.com/in/daksh-vanshaj-9a9650344/", width="stretch")

# --- MAIN INTERFACE ---
tab1, tab2, tab3, tab4 = st.tabs([ "AI Report","BI Executive Dashboard", "Excel Risk Evaluation Tool", "Data Warehouse"])


# Tab 1: AI Situation Room
with tab1:
    st.header("AI Serviellance Report")
    st.markdown("Prompts and data extraction can be changed in n8n for more **Powerful** custom reports, refer to the documenation for templates")
    col_a, col_b = st.columns([2, 1])
    
    with col_a:
        try:
            report = pd.read_sql("SELECT report_html, generated_at FROM latest_ai_report ORDER BY generated_at DESC LIMIT 1", engine)
            
            if not report.empty:
                st.info(f"Report Generated At: {report['generated_at'].dt.tz_localize('UTC').dt.tz_convert('Asia/Kolkata').iloc[0].strftime("%d %b %Y, %I:%M %p")}")

                raw_html = report['report_html'].iloc[0]
                combined_html = f'<div class="report-box">{raw_html}</div>'
                
                # Render the combined string once
                st.markdown(combined_html, unsafe_allow_html=True)
            else:
                st.warning("No AI report found. Trigger an audit to generate one.")
        except:
            st.error("AI Report table not found or empty. Run system sync first.")

    with col_b:
        st.subheader("Actions")
        if st.button("Run AI Risk Audit", width="stretch"):
            with st.spinner("Calling n8n Auditor..."):
                try:
                    # Use the service name 'n8n' for internal container-to-container communication
                    # but fallback to localhost if running outside Docker
                    n8n_host = os.getenv("N8N_HOST", "localhost")
                    response = requests.post(f"http://{n8n_host}:5678/webhook/audit-trigger")
                    
                    if response.status_code == 200:
                        st.success("Audit Requested! Refreshing in 5s...")
                        time.sleep(5)
                        st.rerun()
                    else:
                        st.error(f"Webhook Failed: {response.text}")
                except Exception as e:
                    st.error(f"Could not reach n8n internally. Error: {e}")
        
        st.markdown("---")
        st.subheader( "Active Alert Flags")
        try:
            alerts = pd.read_sql("SELECT state, weighted_risk_score FROM v_critical_alerts WHERE date = (SELECT MAX(date) FROM v_critical_alerts) LIMIT 10", engine)
            if not alerts.empty:
                st.table(alerts)
            else:
                st.success("No active flags for today.")
        except:
            st.caption("Data sync required for alerts.")

    st.markdown("---")
    st.markdown("#### 📥 Download AI Report")
    
    # Safely handle file download
    st.download_button(
        label="Download AI Report",
        data=report['report_html'].iloc[0] if not report.empty else "", # Placeholder for actual report data
        file_name="AI_Risk_Report.html", # Assuming PDF format for a report
        mime="text/html",
        disabled=report.empty, # Disable if no report data
    )

# Tab 2: Power BI Dashboards
with tab2:
    st.header("BI Intelligence (Power BI)")
    st.write("Clean, interactive dashboard for monitoring key COVID-19 metrics, trends and interactions.")

    # Safely handle file download if the file is missing
    pbix_path = "powerbi/covid_power_dashboard.pbix"
    if os.path.exists(pbix_path):
        with open(pbix_path, "rb") as f:
            st.download_button(
                label="Download .PBIX File",
                data=f,
                file_name="Covid_19_Dashboard.pbix",
                mime="application/octet-stream",
                width="stretch"
            )
    else:
        st.warning(f"File not found: {pbix_path}")

    st.image("images/powerbi_dashboard.png", width="stretch")
 

    




# Tab 3: Excel 
with tab3:
    st.header("COVID-19 Risk Evaluation Command Center")
    st.markdown("Adjust the thresholds in the top left or select a state on the right to interact with the model.")
    st.info("Download the Dashboard for smooth interaction, this embed is just for preview. Collapse the sidebar for full view")

    # Safely handle file download
    excel_path = "excel/risk_evaluation_tools.xlsx"
    if os.path.exists(excel_path):
        with open(excel_path, "rb") as f:
            st.download_button(
                label="Download Excel Dashboard",
                data=f,
                file_name="risk_evaluation_tools.xlsx",
                mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                width="stretch"
            )
    else:
        st.warning(f"File not found: {excel_path}")

    # Embed the dashboard
    excel_html = """
<iframe width="100%" height="637" frameborder="0" scrolling="no" src="https://1drv.ms/x/c/7b0d83a227d1b9b8/IQR1-nVTpvVGSoJFktMde1o8AUKGXutz1I0urstDCWd_UcM?wdAllowInteractivity=False&AllowTyping=True&Item=Dashboard_small&wdHideGridlines=True&wdInConfigurator=True&wdInConfigurator=True"></iframe>    """

    # Render the dashboard
    components.html(excel_html, height=637)

# Tab 4: Data Warehouse
with tab4:
    st.header("📂 Data Warehouse (Gold Layer)")
    st.write("Direct access to the cleaned, feature-engineered production tables.")
    
    try:
        df_gold = pd.read_sql("SELECT * FROM covid_summary_clean ORDER BY date DESC", engine)
        
        # Search & Filter
        search = st.text_input("🔍 Search State", "")
        if search:
            # Dropdown/Search filter logic
            df_gold = df_gold[df_gold['state'].str.contains(search, case=False, na=False)]
            
        st.dataframe(df_gold, width="stretch", height=400)
        
        # Download logic
        csv = df_gold.to_csv(index=False).encode('utf-8')
        st.download_button(
            "📥 Export Full Gold Dataset (CSV)",
            data=csv,
            file_name="covid_gold_dataset.csv",
            mime="text/csv",
            width="stretch"
        )
    except:
        st.error("No data found in Gold layer. Please run the ETL pipeline.")

st.markdown("---")
st.caption("COVID-19 Executive Portal")