/*
File: raw_tables.sql

Purpose:
Creates raw staging tables for imported Synthea datasets.

Important Contents:
- Patient data
- Encounter data
- Claims and transaction data

Notes:
- Raw tables preserve source structure
- Used as the initial ingestion layer before dimensional modeling
- Other data included depending how the dashboard is planned
*/

DROP TABLE IF EXISTS patients_raw;
CREATE TABLE patients_raw (
    id TEXT PRIMARY KEY,
    birthdate DATE,
    deathdate DATE,
    ssn TEXT,
    drivers TEXT,
    passport TEXT,
    prefix TEXT,
    first TEXT,
	middle TEXT,
    last TEXT,
    suffix TEXT,
    maiden TEXT,
    marital TEXT,
    race TEXT,
    ethnicity TEXT,
    gender TEXT,
    birthplace TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    county TEXT,
	fips TEXT,
    zip TEXT,
    lat FLOAT,
    lon FLOAT,
    healthcare_expenses FLOAT,
    healthcare_coverage FLOAT,
    income FLOAT
);

DROP TABLE IF EXISTS encounters_raw;
CREATE TABLE encounters_raw (
    id TEXT,
    start TEXT,
    stop TEXT,
    patient TEXT,
    organization TEXT,
    provider TEXT,
    payer TEXT,
    encounterclass TEXT,
    code TEXT,
    description TEXT,
    base_encounter_cost TEXT,
    total_claim_cost TEXT,
    payer_coverage TEXT,
    reason_code TEXT,
    reason_description TEXT
);

DROP TABLE IF EXISTS conditions_raw;
CREATE TABLE conditions_raw (
    start TEXT,
    stop TEXT,
    patient TEXT,
    encounter TEXT,
	system TEXT,
    code TEXT,
    description TEXT
);

DROP TABLE IF EXISTS procedures_raw;
CREATE TABLE procedures_raw (
    start TEXT,
    stop TEXT,
    patient TEXT,
    encounter TEXT,
	system TEXT,
    code TEXT,
    description TEXT,
    base_cost TEXT,
    reason_code TEXT,
    reason_description TEXT
);

DROP TABLE IF EXISTS medications_raw;
CREATE TABLE medications_raw (
    start TEXT,
    stop TEXT,
    patient TEXT,
    payer TEXT,
    encounter TEXT,
    code TEXT,
    description TEXT,
    base_cost TEXT,
    payer_coverage TEXT,
    dispenses TEXT,
    totalcost TEXT,
    reason_code TEXT,
    reason_description TEXT
);

DROP TABLE IF EXISTS observations_raw;
CREATE TABLE observations_raw (
    date TEXT,
    patient TEXT,
    encounter TEXT,
    category TEXT,
    code TEXT,
    description TEXT,
    value TEXT,
    units TEXT,
    type TEXT
);

DROP TABLE IF EXISTS claims_raw;
CREATE TABLE claims_raw (
    id TEXT,
    patient TEXT,
    provider TEXT,
    primary_insurance_id TEXT,
    secondary_insurance_id TEXT,
    department_id TEXT,
    patient_department_id TEXT,
    diagnosis1 TEXT,
    diagnosis2 TEXT,
    diagnosis3 TEXT,
    diagnosis4 TEXT,
    diagnosis5 TEXT,
    diagnosis6 TEXT,
    diagnosis7 TEXT,
    diagnosis8 TEXT,
    referring_provider_id TEXT,
    appointment_id TEXT,
    current_illness_date TEXT,
    servicedate TEXT,
    supervising_provider_id TEXT,
    status1 TEXT,
    status2 TEXT,
    statusp TEXT,
    outstanding1 TEXT,
    outstanding2 TEXT,
    outstandingp TEXT,
    lastbilleddate1 TEXT,
    lastbilleddate2 TEXT,
    lastbilleddatep TEXT,
    healthcare_claim_type_id1 TEXT,
    healthcare_claim_type_id2 TEXT
);

DROP TABLE IF EXISTS claims_transactions_raw;
CREATE TABLE claims_transactions_raw (
    id TEXT,
    claim_id TEXT,
    chargeid TEXT,
    patientid TEXT,
    type TEXT,
    amount TEXT,
    method TEXT,
    fromdate TEXT,
    todate TEXT,
    place_of_service TEXT,
    procedure_code TEXT,
    modifier1 TEXT,
    modifier2 TEXT,
    diagnosisref1 TEXT,
    diagnosisref2 TEXT,
    diagnosisref3 TEXT,
    diagnosisref4 TEXT,
    units TEXT,
    department_id TEXT,
    notes TEXT,
    unitamount TEXT,
    transferoutid TEXT,
    transfertype TEXT,
    payments TEXT,
    adjustments TEXT,
    transfers TEXT,
    outstanding TEXT,
    appointmentid TEXT,
    linenote TEXT,
    patientinsuranceid TEXT,
    feescheduleid TEXT,
    providerid TEXT,
    supervisingproviderid TEXT
);

DROP TABLE IF EXISTS payers_raw;
CREATE TABLE payers_raw (
    id TEXT,
    name TEXT,
	ownership TEXT,
    address TEXT,
    city TEXT,
    state_headquartered TEXT,
    zip TEXT,
    phone TEXT,
    amount_covered TEXT,
    amount_uncovered TEXT,
    revenue TEXT,
    covered_encounters TEXT,
    uncovered_encounters TEXT,
    covered_medications TEXT,
    uncovered_medications TEXT,
    covered_procedures TEXT,
    uncovered_procedures TEXT,
    covered_immunizations TEXT,
    uncovered_immunizations TEXT,
    unique_customers TEXT,
    qols_avg TEXT,
    member_months TEXT
);