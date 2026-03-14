# AI Intelligence Setup: Data + Prompts

This document provides the complete setup for the system's "Brain." By combining specific **SQL Data Signals** with **AI System Prompts**, we can generate targeted intelligence for different stakeholders.

Note: The results are dependent on the type of model you choose. More complex models can generate even interactive html reports that cover a wide range of analysis.
However, these prompts are optimized for free to use gemma3 model in n8n.
You can connect n8n to local model as well, support for which will be added in future.

---

## Combination 1: The Critical Outbreak Alert (Alert Focused)
**Goal**: Technical analysis and immediate containment guidance for high-risk zones.

### **1. The Data Signal (SQL)**

```sql
-- Focuses only on states exceeding the risk threshold
SELECT 
    state, 
    daily_new_cases, 
    positive_test_rate, 
    weighted_risk_score 
FROM v_critical_alerts 
WHERE date = (SELECT MAX(date) FROM v_critical_alerts);
-- AND weighted_risk_score > 20; optional
```

### **2. The System Prompt**

```text
You are a Public Health Data Intelligence Officer. Generate a professional COVID-19 Situation Report in HTML format for {{ $json.count }} states at risk.

CRITICAL INSTRUCTIONS:

- Return ONLY the raw HTML code.
- Do NOT include any markdown code blocks (NO ```html or ```).
- Do NOT include any introductory or explanatory text outside the HTML.
- All styles must be inline CSS for email compatibility.

DATA FOR ANALYSIS:

{{ $json.full_data }}

STRUCTURE:

1. <h3>Executive Summary</h3>: A 2-sentence synthesis of current risk.
2. <h3>High-Risk Jurisdictions</h3>: An HTML table showing State, Positivity, and Risk Score.
3. <h3>Recommended Actions</h3>: 3 specific bullet points for resource mobilization.
4. <h3>System Tuning (Human-in-the-Loop)</h3>:

   Include these two styled buttons or links:

   - [Confirm Outbreak] -> http://localhost:5678/webhook/covid-feedback?status=Confirmed&state=ALL&date={{ $json.date }}
   - [False Alarm] -> http://localhost:5678/webhook/covid-feedback?status=False Positive&state=ALL&date={{ $json.date }}

```
---

## Combination 2: The National Executive Briefing (Complete Report)
**Goal**: Provide a 360-degree strategic summary for high-level decision-makers.

### **1. The Data Signal (SQL)**

```sql
-- Extracts all metrics for all states to give the AI full context
SELECT * 
FROM covid_summary_clean c
LEFT JOIN v_critical_alerts v
ON c.state = v.state AND c.date = v.date
WHERE c.date = (SELECT MAX(date) FROM covid_summary_clean)
LIMIT 50;
```

### **2. The System Prompt**

```text
You are a Chief Medical Officer. Based on the provided COVID-19 data, generate a strategic HTML briefing.

DATA:

{{ $json.full_data }}

STRUCTURE:

1. Executive Summary: 2-3 sentences on the national outlook.
2. Resource Mobilization: Identify the top 3 states needing immediate oxygen or bed capacity increases.
3. Policy Recommendation: Suggest 1 policy change based on the trends.

GUARDRAILS:

- Return ONLY raw HTML with inline CSS.
- Use only the data provided.
- Include Confirm/False Alarm links at the bottom.
```

---

## Combination 3: Public Health Awareness Update
**Goal**: Simple, non-alarmist communication for the general public.

### **1. The Data Signal (SQL)**

```sql
-- Focuses on vaccination progress and testing volume
SELECT 
    state, 
    vaccination_rate, 
    totalsamples, 
    population
FROM covid_summary_clean 
WHERE date = (SELECT MAX(date) FROM covid_summary_clean)
ORDER BY vaccination_rate ASC;
```

### **2. The System Prompt**

```text
You are a Public Health Communications Officer. Generate a community-focused update.

DATA:

{{ $json.full_data }}

TASK:

1. Current Status: Use clear, simple language to explain the risk level.
2. Protective Actions: List 3 steps citizens should take today.
3. Reassurance: Highlight vaccination progress to provide a balanced perspective.

GUARDRAILS:

- Return ONLY raw HTML. Use large font sizes for key takeaways.
- Do NOT use technical jargon.
```

---

## Prompting Best Practices
To ensure the system works reliably in both Gmail and the Streamlit Portal:

*   **Output Control**: Always specify "Return ONLY raw HTML."
*   **Styling**: Use **inline CSS** (e.g., `<div style='color:red;'>`) because many email clients strip out `<style>` blocks.
*   **Data Integrity**: Explicitly tell the AI not to "hallucinate" or invent data not found in the SQL result.
