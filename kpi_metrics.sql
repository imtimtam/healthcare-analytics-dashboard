/*
File: kpi_metrics.sql

Purpose:
Defines analytical views and KPI calculations used in Power BI dashboards.

Contents:
- Financial metrics
- Utilization metrics
- Revenue cycle calculations
- Aggregated reporting views

Notes:
- Mainly used for exploratory analysis and KPI validation
- Some metrics are recreated dynamically in Power BI using DAX
*/

-- COUNT AND JOIN VALIDATION
SELECT *
FROM fact_encounters e
JOIN dim_patient p ON e.patient_id = p.patient_id
LIMIT 10

SELECT COUNT(*)
FROM fact_encounters e

SELECT COUNT(*)
FROM fact_encounters e
LEFT JOIN dim_payer p ON e.payer = p.payer_id
WHERE p.payer_id IS NOT NULL

SELECT COUNT(*)
FROM fact_claims

SELECT COUNT(*)
FROM fact_claims c
LEFT JOIN dim_patient p ON c.patient_id = p.patient_id
WHERE p.patient_id IS NOT NULL

SELECT *
FROM fact_claims c
JOIN fact_encounters e
ON c.encounter_id = e.encounter_id;

SELECT *
FROM fact_claim_transactions t
JOIN fact_claims c
ON t.claim_id = c.claim_id;

-- CREATE KPI & OTHER METRICS
-- UTILIZATION METRICS
SELECT *
FROM fact_encounters
LIMIT 100

-- SUMs, AVGs
WITH base AS (
    SELECT *
    FROM fact_encounters
    WHERE start_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
)
SELECT 
	SUM(total_claim_cost),
	AVG(total_claim_cost),
	SUM(payer_coverage),
	AVG(payer_coverage),
	COUNT(*) * 1.0 / COUNT(DISTINCT patient_id) AS avg_encounters_per_patient
FROM base

-- Average encounters per patients each year
WITH base AS (
    SELECT *
    FROM fact_encounters
    WHERE start_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
)
SELECT 
    AVG(encounters_per_year)
FROM (
    SELECT
        patient_id,
        EXTRACT(YEAR FROM start_time) AS year,
        COUNT(*) AS encounters_per_year
    FROM base
    GROUP BY patient_id, year
) t;

-- Visit bucket counts
CREATE OR REPLACE VIEW utilization_visit_buckets AS
WITH base AS (
    SELECT *
    FROM fact_encounters
    WHERE start_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
),
patient_counts AS (
	SELECT patient_id, COUNT(*) AS cnt
    FROM base
    GROUP BY patient_id
)
SELECT
    CASE 
        WHEN cnt = 1 THEN '1'
        WHEN cnt BETWEEN 2 AND 5 THEN '2–5'
        WHEN cnt BETWEEN 6 AND 10 THEN '6–10'
        WHEN cnt BETWEEN 11 AND 20 THEN '11–20'
        WHEN cnt BETWEEN 21 AND 50 THEN '21–50'
        WHEN cnt BETWEEN 51 AND 100 THEN '51–100'
        ELSE '100+'
    END AS visit_bucket,
    COUNT(*) AS patient_count
FROM patient_counts
GROUP BY 1
ORDER BY 2 DESC;

-- Visit types and average time
WITH base AS (
    SELECT *
    FROM fact_encounters
    WHERE start_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
)
SELECT 
	encounterclass,
	COUNT(*),
	ROUND(AVG(EXTRACT(EPOCH FROM (stop_time - start_time)) / 60), 0) AS avg_minutes
FROM base
GROUP BY 1
ORDER BY 2 DESC;

-- Encounters per year
WITH base AS (
    SELECT *
    FROM fact_encounters
    WHERE start_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
)
SELECT
    EXTRACT(YEAR FROM start_time) AS year,
    COUNT(*) AS encounters
FROM base
GROUP BY 1
ORDER BY 1 DESC;

-- Encounters per month and year
WITH base AS (
    SELECT *
    FROM fact_encounters
    WHERE start_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
)
SELECT
    DATE_TRUNC('month', start_time) AS month,
    COUNT(*) AS encounters
FROM base
GROUP BY 1
ORDER BY 1;

-- Distinct patients per month
WITH base AS (
    SELECT *
    FROM fact_encounters
    WHERE start_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
)
SELECT
    DATE_TRUNC('month', start_time) AS month,
    COUNT(DISTINCT patient_id) AS patients
FROM base
GROUP BY 1
ORDER BY 1;

-- Average encounters per patient per year
WITH base AS (
    SELECT *
    FROM fact_encounters
    WHERE start_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
)
SELECT
    EXTRACT(YEAR FROM start_time) AS year,
    COUNT(*) * 1.0 / COUNT(DISTINCT patient_id) AS avg_encounters_per_patient
FROM base
GROUP BY 1
ORDER BY 1;


-- Create Utilizations Views
CREATE OR REPLACE VIEW utilization_summary AS
WITH base AS (
    SELECT *
    FROM fact_encounters
    WHERE start_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
),
yearly AS (
    SELECT
        patient_id,
        EXTRACT(YEAR FROM start_time) AS year,
        COUNT(*) AS encounters_per_year
    FROM base
    GROUP BY patient_id, year
)
SELECT 
	COUNT(*) AS total_encounters,
	COUNT(DISTINCT patient_id) AS total_patients,
	ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT patient_id), 1) AS avg_encounters_per_patient,
	ROUND((SELECT AVG(encounters_per_year) FROM yearly), 2) AS avg_encounters_per_year,
	ROUND(AVG(EXTRACT(EPOCH FROM (stop_time - start_time)) / 60), 0) AS avg_encounter_minutes
FROM base;

CREATE OR REPLACE VIEW utilization_monthly_trends AS 
WITH base AS (
    SELECT *
    FROM fact_encounters
    WHERE start_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
)
SELECT
	DATE_TRUNC('month', start_time) AS month,
	COUNT(*) AS encounters,
	COUNT(DISTINCT patient_id) AS distinct_patients,
	ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT patient_id), 2) AS avg_encounters_per_patient
FROM base
GROUP BY 1;

CREATE OR REPLACE VIEW utilization_yearly AS
WITH base AS (
    SELECT *
    FROM fact_encounters
    WHERE start_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
)
SELECT
    EXTRACT(YEAR FROM start_time) AS year,
    COUNT(*) AS encounters,
    COUNT(DISTINCT patient_id) AS patients,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT patient_id), 2) AS avg_encounters_per_patient
FROM base
GROUP BY 1
ORDER BY 1;

CREATE OR REPLACE VIEW utilization_by_class AS
WITH base AS (
    SELECT *
    FROM fact_encounters
    WHERE start_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
)
SELECT
    encounterclass,
    COUNT(*) AS encounters,
    ROUND(AVG(EXTRACT(EPOCH FROM (stop_time - start_time)) / 60), 0) AS avg_minutes
FROM base
GROUP BY 1;

SELECT *
FROM fact_claims
LIMIT 10

CREATE OR REPLACE VIEW utilization_visit_buckets AS
WITH base AS (
    SELECT *
    FROM fact_encounters
    WHERE start_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
),
patient_counts AS (
	SELECT patient_id, COUNT(*) AS cnt
    FROM base
    GROUP BY patient_id
)
SELECT
    CASE 
        WHEN cnt = 1 THEN '1'
        WHEN cnt BETWEEN 2 AND 5 THEN '2–5'
        WHEN cnt BETWEEN 6 AND 10 THEN '6–10'
        WHEN cnt BETWEEN 11 AND 20 THEN '11–20'
        WHEN cnt BETWEEN 21 AND 50 THEN '21–50'
        WHEN cnt BETWEEN 51 AND 100 THEN '51–100'
        ELSE '100+'
    END AS visit_bucket,
    COUNT(*) AS patient_count
FROM patient_counts
GROUP BY 1;

CREATE OR REPLACE VIEW utilization_by_payer AS
WITH base AS (
    SELECT *
    FROM fact_encounters
    WHERE start_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
)
SELECT
	payer_id,
	COUNT(*) AS encounters,
	COUNT(DISTINCT(patient_id)) AS patients
FROM base
GROUP BY payer_id;


-- Create Financial Views
CREATE OR REPLACE VIEW financial_encounters AS
WITH base AS (
    SELECT *
    FROM fact_encounters
    WHERE start_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
)
SELECT
	ROUND(SUM(total_claim_cost), 0) AS total_billed,
	ROUND(SUM(payer_coverage), 0) AS expected_coverage,
	ROUND(SUM(payer_coverage) * 1.0 / NULLIF(SUM(total_claim_cost), 0), 2) AS coverage_ratio
FROM base;

CREATE OR REPLACE VIEW financial_transactions AS
WITH base AS (
    SELECT *
    FROM fact_claim_transactions
    WHERE from_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
),
latest AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY claim_id ORDER BY to_time DESC) AS rn
    FROM base
)
SELECT
    ROUND(SUM(payments), 0) AS total_paid,
    ROUND(SUM(adjustments), 0) AS total_adjustments,
    ROUND(SUM(CASE WHEN rn = 1 THEN outstanding END), 0) AS total_outstanding
FROM latest;

CREATE OR REPLACE VIEW financial_billed_monthly AS
WITH base AS (
    SELECT *
    FROM fact_encounters
    WHERE start_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
)
SELECT
	DATE_TRUNC('month', start_time) AS month,
	ROUND(SUM(total_claim_cost), 0) AS billed,
	ROUND(SUM(payer_coverage), 0) AS covered
FROM base
GROUP BY 1;

CREATE OR REPLACE VIEW financial_paid_monthly AS
WITH base AS (
    SELECT *
    FROM fact_claim_transactions
    WHERE from_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
)
SELECT
    DATE_TRUNC('month', from_time) AS month,
    ROUND(SUM(payments), 0) AS paid,
    ROUND(SUM(adjustments), 0) AS adjustments
FROM base
GROUP BY 1;

CREATE OR REPLACE VIEW financial_outstanding_latest AS
WITH base AS (
    SELECT *
    FROM fact_claim_transactions
    WHERE from_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
),
latest AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY claim_id ORDER BY to_time DESC) AS rn
    FROM base
)
SELECT
    ROUND(SUM(outstanding), 0) AS total_outstanding
FROM latest
WHERE rn = 1;

CREATE OR REPLACE VIEW financial_billed_yearly AS
SELECT
    EXTRACT(YEAR FROM start_time) AS year,
    SUM(total_claim_cost) AS billed
FROM fact_encounters
WHERE start_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
GROUP BY 1;

CREATE OR REPLACE VIEW financial_paid_yearly AS
SELECT
    EXTRACT(YEAR FROM from_time) AS year,
    SUM(payments) AS paid
FROM fact_claim_transactions
WHERE from_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
GROUP BY 1;

CREATE OR REPLACE VIEW financial_revenue_monthly AS
SELECT
    b.month,
    b.billed,
    p.paid,
	ROUND(COALESCE(p.paid, 0) * 1.0 / NULLIF(b.billed, 0), 2) AS collection_ratio
FROM financial_billed_monthly b
LEFT JOIN financial_paid_monthly p ON b.month = p.month;

CREATE OR REPLACE VIEW financial_billed_by_payer AS
WITH base AS (
    SELECT *
    FROM fact_encounters
    WHERE start_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
)
SELECT
	payer_id,
	COUNT(DISTINCT patient_id) AS patients,
	SUM(total_claim_cost) AS billed,
	SUM(payer_coverage) AS expected_coverage
FROM base
GROUP BY payer_id;

CREATE OR REPLACE VIEW financial_billed_monthly_payer AS
WITH base AS (
    SELECT *
    FROM fact_encounters
    WHERE start_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
)
SELECT
    DATE_TRUNC('month', start_time) AS month,
    payer_id,
    SUM(total_claim_cost) AS billed
FROM base
GROUP BY 1, 2;

CREATE OR REPLACE VIEW financial_paid_monthly_payer AS
WITH base AS (
    SELECT 
		t.*,
		COALESCE(c.payer_id,'e03e23c9-4df1-3eb6-a62d-f70f02301496') AS payer_id
    FROM fact_claim_transactions t
	JOIN fact_claims c ON t.claim_id = c.claim_id
    WHERE t.from_time >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '10 years'
)
SELECT
    DATE_TRUNC('month', from_time) AS month,
    payer_id,
    SUM(payments) AS paid,
	SUM(adjustments) AS adjustments
FROM base
GROUP BY 1, 2;

CREATE OR REPLACE VIEW financial_revenue_monthly_payer AS
SELECT
    b.month,
    b.payer_id,
    b.billed,
    p.paid,
    ROUND(COALESCE(p.paid, 0) * 1.0 / NULLIF(b.billed, 0), 2) AS collection_ratio
FROM financial_billed_monthly_payer b
LEFT JOIN financial_paid_monthly_payer p
    ON b.month = p.month
    AND b.payer_id = p.payer_id;