/*
====================================================================================
COVID-19 DATA PIPELINE: END-TO-END ETL SCRIPT
Architecture: Medallion (Bronze -> Silver -> Gold)
====================================================================================
*/

/*
====================================================================================
PHASE 1: BRONZE LAYER (EXTRACTION & STAGING)
Why: Raw data is messy. Loading everything as TEXT prevents ingestion crashes 
caused by stray commas, dashes, or mixed date formats in the CSV files.
====================================================================================
*/

-- CASCADE is an instruction to automatically remove any database objects that depend on the table you are dropping.
DROP TABLE IF EXISTS covid_19_india_staging CASCADE;
CREATE TABLE covid_19_india_staging (
    sno TEXT,
    date TEXT,
    time TEXT,
    state_unionterritory TEXT,
    confirmedindiannational TEXT,
    confirmedforeignnational TEXT,
    cured TEXT,
    deaths TEXT,
    confirmed TEXT
);

DROP TABLE IF EXISTS covid_vaccine_statewise_staging CASCADE;
CREATE TABLE covid_vaccine_statewise_staging (
    updated_on TEXT,
    state TEXT,
    total_doses_administered TEXT,
    sessions TEXT,
    sites TEXT,
    first_dose_administered TEXT,
    second_dose_administered TEXT,
    male_doses_administered TEXT,
    female_doses_administered TEXT,
    transgender_doses_administered TEXT,
    covaxin_doses TEXT,
    covishield_doses TEXT,
    sputnik_v_doses TEXT,
    aefi TEXT,
    dose_18_44 TEXT,
    dose_45_60 TEXT,
    dose_60_plus TEXT,
    ind_18_44 TEXT,
    ind_45_60 TEXT,
    ind_60_plus TEXT,
    male_ind TEXT,
    female_ind TEXT,
    transgender_ind TEXT,
    total_individuals_vaccinated TEXT
);

DROP TABLE IF EXISTS statewisetestingdetails_staging CASCADE;
CREATE TABLE statewisetestingdetails_staging (
    date TEXT,
    state TEXT,
    totalsamples TEXT,
    negative TEXT,
    positive TEXT
);

/*
===================================================================================
REMOVE HEADERS if present

*/

-- Remove the header row from the Cases staging table
DELETE FROM covid_19_india_staging 
WHERE date = 'Date' OR date = 'date';

-- Remove the header row from the Testing staging table
DELETE FROM statewisetestingdetails_staging 
WHERE date = 'Date' OR date = 'date';

-- Remove the header row from the Vaccine staging table
DELETE FROM covid_vaccine_statewise_staging 
WHERE updated_on = 'Updated On' OR updated_on = 'updated_on';



/*
====================================================================================
PHASE 2: SILVER LAYER (DATA CLEANING, CASTING & STANDARDIZATION)
Why: We must normalize state names to avoid fragmented aggregations and safely 
convert TEXT into usable DATE and NUMERIC types for mathematical operations.
How: We use `CREATE TABLE AS SELECT` (modern syntax).
====================================================================================
*/

-- 1. Clean Cases Data
DROP TABLE IF EXISTS silver_cases CASCADE;
CREATE TABLE silver_cases AS
SELECT 
    -- Standardize state names dynamically using CASE statements
    CASE 
        WHEN TRIM(state_unionterritory) = 'Karanataka' THEN 'Karnataka'
        WHEN TRIM(state_unionterritory) = 'Himanchal Pradesh' THEN 'Himachal Pradesh'
        WHEN TRIM(state_unionterritory) = 'Telengana' THEN 'Telangana'
        WHEN TRIM(state_unionterritory) LIKE 'Bihar%' THEN 'Bihar'
        WHEN TRIM(state_unionterritory) LIKE 'Madhya Pradesh%' THEN 'Madhya Pradesh'
        WHEN TRIM(state_unionterritory) LIKE 'Maharashtra%' THEN 'Maharashtra'
        WHEN TRIM(state_unionterritory) IN ('Dadra and Nagar Haveli', 'Daman & Diu') 
             THEN 'Dadra and Nagar Haveli and Daman and Diu'
        ELSE TRIM(state_unionterritory)
    END AS state,
    
    -- Dynamically parse different date formats found in the raw CSV
    CASE 
        WHEN date LIKE '%/%' THEN TO_DATE(date, 'MM/DD/YYYY')
        -- Default YYYY-MM-DD
        WHEN date LIKE '%-%' THEN date::DATE
        ELSE NULL
    END AS record_date,
    
    -- Strip dashes and cast to Integer, defaulting to 0 if null
    COALESCE(NULLIF(NULLIF(confirmedindiannational, '-'), ''), '0')::INT + 
    COALESCE(NULLIF(NULLIF(confirmedforeignnational, '-'), ''), '0')::INT AS total_confirmed,
    COALESCE(NULLIF(NULLIF(cured, '-'), ''), '0')::INT AS cured,
    COALESCE(NULLIF(NULLIF(deaths, '-'), ''), '0')::INT AS deaths,
    COALESCE(NULLIF(NULLIF(confirmed, '-'), ''), '0')::INT AS confirmed
FROM covid_19_india_staging
-- Filter out administrative junk rows
WHERE state_unionterritory NOT IN ('Cases being reassigned to states', 'Unassigned');


-- 2. Clean Testing Data
DROP TABLE IF EXISTS silver_testing CASCADE;
CREATE TABLE silver_testing AS
SELECT
    TRIM(state) AS state,
    CASE 
        WHEN date LIKE '%/%' THEN TO_DATE(date, 'MM/DD/YYYY')
        WHEN date LIKE '%-%' THEN date::DATE
        ELSE NULL
    END AS record_date,
    COALESCE(NULLIF(NULLIF(TRIM(totalsamples), '-'), ''), '0')::NUMERIC::BIGINT AS totalsamples,
    COALESCE(NULLIF(NULLIF(TRIM(positive), '-'), ''), '0')::NUMERIC::BIGINT AS positive
FROM statewisetestingdetails_staging;


-- 3. Clean Vaccine Data
DROP TABLE IF EXISTS silver_vaccines CASCADE;
CREATE TABLE silver_vaccines AS
SELECT
    TRIM(state) AS state,
    CASE 
        WHEN updated_on LIKE '%/%' THEN TO_DATE(updated_on, 'DD/MM/YYYY')
        WHEN updated_on LIKE '%-%' THEN updated_on::DATE
        ELSE NULL
    END AS record_date,
    COALESCE(NULLIF(NULLIF(TRIM(total_doses_administered), '-'), ''), '0')::NUMERIC::BIGINT AS total_doses,
    COALESCE(NULLIF(NULLIF(TRIM(first_dose_administered), '-'), ''), '0')::NUMERIC::BIGINT AS first_dose,
    COALESCE(NULLIF(NULLIF(TRIM(second_dose_administered), '-'), ''), '0')::NUMERIC::BIGINT AS second_dose
FROM covid_vaccine_statewise_staging
WHERE TRIM(state) != 'India'; -- Exclude national aggregations to prevent double counting


/*
====================================================================================
PHASE 3: STATIC DIMENSION TABLES
Why: Hardcoding variables like population inside complex analytical queries is poor 
practice. A dimension table keeps logic clean and allows for easy updates.
====================================================================================
*/

DROP TABLE IF EXISTS dim_state_population CASCADE;
CREATE TABLE dim_state_population (state VARCHAR(100), population BIGINT);
INSERT INTO dim_state_population (state, population) VALUES
('Andaman and Nicobar Islands', 380581), ('Andhra Pradesh', 49577103), ('Arunachal Pradesh', 1504000),
('Assam', 35607039), ('Bihar', 124799926), ('Chandigarh', 1158473), ('Chhattisgarh', 29436231),
('Dadra and Nagar Haveli and Daman and Diu', 586956), ('Delhi', 19814000), ('Goa', 1586250),
('Gujarat', 67936000), ('Haryana', 29260000), ('Himachal Pradesh', 7400000), ('Jammu and Kashmir', 13800000),
('Jharkhand', 38593948), ('Karnataka', 69144000), ('Kerala', 35699443), ('Ladakh', 293000),
('Lakshadweep', 64473), ('Madhya Pradesh', 85358965), ('Maharashtra', 123144223), ('Manipur', 3070000),
('Meghalaya', 3366710), ('Mizoram', 1239244), ('Nagaland', 2249695), ('Odisha', 46356334),
('Punjab', 30141373), ('Rajasthan', 81032689), ('Sikkim', 690251), ('Tamil Nadu', 77841267),
('Telangana', 35003674), ('Tripura', 4169794), ('Uttar Pradesh', 241066874), ('Uttarakhand', 11840895),
('West Bengal', 99609303), ('Puducherry', 1549000);


/*
====================================================================================
PHASE 4: GOLD LAYER (FEATURE ENGINEERING & INTEGRATION)
Why: This builds the production-ready table. We engineer daily new cases using LAG,
impute missing testing/vaccine data using MAX() forward-fills, and apply the 
conditional risk logic required for dashboarding and alerting.
====================================================================================
*/

-- CREATE TABLE table_name AS       -- Layer 1: Destination
--     WITH cte_name AS (           -- Layer 2: Transformation Logic
--         SELECT ... FROM ...
--     ),
--     another_cte AS (
--         SELECT ... FROM cte_name
--     )
-- SELECT * FROM another_cte;       -- Layer 3: Final Output Selection

DROP TABLE IF EXISTS covid_summary CASCADE;
CREATE TABLE covid_summary AS
WITH engineered_cases AS (
    SELECT 
        state,
        record_date,
        confirmed,
        deaths,
        cured,
        -- Feature Engineering: Calculate daily cases by subtracting yesterday from today
        confirmed - LAG(confirmed, 1, 0) OVER (PARTITION BY state ORDER BY record_date) AS daily_new_cases
    FROM silver_cases
),
joined_data AS (
    SELECT 
        c.state,
        c.record_date AS date,
        c.confirmed,
        c.deaths,
        c.cured,
        c.daily_new_cases,
        
        -- Forward-fill missing testing data for days states didn't report
        MAX(t.totalsamples) OVER (PARTITION BY c.state ORDER BY c.record_date 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS totalsamples,
        MAX(t.positive) OVER (PARTITION BY c.state ORDER BY c.record_date 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS positive,
            
        -- Forward-fill missing vaccination data
        MAX(v.total_doses) OVER (PARTITION BY c.state ORDER BY c.record_date 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_doses_administered,
            
        p.population
    FROM engineered_cases c
    LEFT JOIN silver_testing t ON c.state = t.state AND c.record_date = t.record_date
    LEFT JOIN silver_vaccines v ON c.state = v.state AND c.record_date = v.record_date
    LEFT JOIN dim_state_population p ON c.state = p.state
)
SELECT 
    state,
    date,
    confirmed,
    deaths,
    cured,
    daily_new_cases,
    totalsamples,
    positive,
    total_doses_administered,
    population,
    
    -- KPI 1: Case Fatality Rate (Protected against division by zero)
    CASE 
        WHEN confirmed > 0 THEN ROUND((deaths::DECIMAL / confirmed) * 100, 2)
        ELSE 0 
    END AS case_fatality_rate,

    -- KPI 2: Test Positivity Rate
    CASE 
        WHEN totalsamples > 0 THEN ROUND((positive::DECIMAL / totalsamples) * 100, 2)
        ELSE 0 
    END AS positive_test_rate,

    -- KPI 3: Vaccination Rate
    CASE 
        WHEN population > 0 THEN ROUND((total_doses_administered::DECIMAL / population) * 100, 2)
        ELSE 0 
    END AS vaccination_rate,

    -- Business Logic: Risk Classification Rule Engine
    CASE 
        WHEN (confirmed > 0 AND (deaths::DECIMAL / confirmed) * 100 > 2) AND 
             (totalsamples > 0 AND (positive::DECIMAL / totalsamples) * 100 > 10) 
        THEN 'High Risk'
        
        WHEN (confirmed > 0 AND (deaths::DECIMAL / confirmed) * 100 > 2) OR 
             (totalsamples > 0 AND (positive::DECIMAL / totalsamples) * 100 > 10) 
        THEN 'Medium Risk'
        
        ELSE 'Low Risk'
    END AS risk_level

FROM joined_data;


/*
====================================================================================
PHASE 5: DATA VALIDATION & DEDUPLICATION
Why: Ensure no duplicate rows were generated during the table joins before 
the dataset is exported to Excel or PowerBI.
====================================================================================
*/

DROP TABLE IF EXISTS covid_summary_clean CASCADE;
CREATE TABLE covid_summary_clean AS
SELECT 
    state, date, confirmed, deaths, cured, daily_new_cases, 
    totalsamples, positive, positive_test_rate, total_doses_administered, 
    population, vaccination_rate, case_fatality_rate, risk_level
FROM (
    -- Use ROW_NUMBER to identify duplicates based on the state and date timeline
    SELECT *, ROW_NUMBER() OVER (PARTITION BY state, date ORDER BY confirmed DESC) AS duplicate_flag
    FROM covid_summary
) deduplicated_set
WHERE duplicate_flag = 1;

-- Final output for verification
SELECT * FROM covid_summary_clean ORDER BY state, date LIMIT 50;