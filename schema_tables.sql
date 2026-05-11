/*
File: schema_tables.sql

Purpose:
Creates the dimensional star schema used for analytics and reporting.

Contents:
- Dimension tables
- Fact tables
- Relationships and keys

Notes:
- Designed for Power BI reporting
- Mainly supports utilization, financial, and payer analytics
*/

DROP TABLE IF EXISTS dim_patient;
CREATE TABLE dim_patient AS
SELECT
    id AS patient_id,
    birthdate,
    deathdate,
    gender,
    race,
    ethnicity,
    city,
    state,
    county,
    zip,
    income::NUMERIC(12,2)
FROM patients_raw;

DROP TABLE IF EXISTS dim_payer;
CREATE TABLE dim_payer AS
SELECT
    id AS payer_id,
    name,
    ownership,
    state_headquartered
FROM payers_raw;

DROP TABLE IF EXISTS fact_encounters;
CREATE TABLE fact_encounters AS
SELECT
    id AS encounter_id,
    patient AS patient_id,
    provider AS provider_id,
    organization AS organization_id,
    payer AS payer_id,
    start::TIMESTAMPTZ AS start_time,
    stop::TIMESTAMPTZ AS stop_time,
    encounterclass,
    base_encounter_cost::NUMERIC(12,2),
    total_claim_cost::NUMERIC(12,2),
    payer_coverage::NUMERIC(12,2),
    reason_code
FROM encounters_raw;

DROP TABLE IF EXISTS fact_conditions;
CREATE TABLE fact_conditions AS
SELECT
    patient AS patient_id,
    encounter AS encounter_id,
    start::TIMESTAMPTZ AS start_time,
    code,
    description
FROM conditions_raw;

DROP TABLE IF EXISTS fact_procedures;
CREATE TABLE fact_procedures AS
SELECT
    patient AS patient_id,
    encounter AS encounter_id,
    start::TIMESTAMPTZ AS start_time,
    code,
    base_cost::NUMERIC(12,2)
FROM procedures_raw;

DROP TABLE IF EXISTS fact_medications;
CREATE TABLE fact_medications AS
SELECT
    patient AS patient_id,
    encounter AS encounter_id,
    start::TIMESTAMPTZ AS start_time,
    code,
    totalcost::NUMERIC(12,2),
    payer_coverage::NUMERIC(12,2)
FROM medications_raw;

DROP TABLE IF EXISTS fact_observations;
CREATE TABLE fact_observations AS
SELECT
    patient AS patient_id,
    encounter AS encounter_id,
    date::TIMESTAMPTZ AS observation_time,
    code,
    value,
    units
FROM observations_raw;

DROP TABLE IF EXISTS fact_claims;
CREATE TABLE fact_claims AS
SELECT
    id AS claim_id,
    patient AS patient_id,
    provider AS provider_id,
    primary_insurance_id AS payer_id,
	appointment_id AS en
    servicedate::TIMESTAMPTZ AS service_time,
    status1,
    statusp
FROM claims_raw;

DROP TABLE IF EXISTS fact_claim_transactions;
CREATE TABLE fact_claim_transactions AS
SELECT
    id,
    claim_id,
    patientid AS patient_id,
    type,
    amount::NUMERIC(12,2),
    method,
    fromdate::TIMESTAMPTZ AS from_time, 
    todate::TIMESTAMPTZ AS to_time,
    payments::NUMERIC(12,2),
    adjustments::NUMERIC(12,2),
    outstanding::NUMERIC(12,2),
    providerid AS provider_id
FROM claims_transactions_raw;