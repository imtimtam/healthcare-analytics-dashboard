-- COVID-19 California 2020 Analysis
-- Create view for query efficiency and limit to California 2020 (start of outbreak)
-- Uncomment below to create `hcdata1.covid_analysis.ca_covid_2020_view` used for the final version, `hcdata1.covid_analysis.ca_covid_2020_final`

/*
CREATE OR REPLACE VIEW `hcdata1.covid_analysis.ca_covid_2020_view` AS 
SELECT
  date,
  REPLACE(datacommons_id, 'geoId/', '') AS geo_id,
  subregion1_name,
  subregion2_name,
  new_confirmed,
  new_deceased,
  population
FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE country_code = 'US' AND subregion1_name = 'California' AND EXTRACT(YEAR FROM date) = 2020;
*/

CREATE OR REPLACE VIEW `hcdata1.covid_analysis.ca_covid_2020_final` AS 
-- Aggregate COVID data by county
WITH covid_agg AS (
  SELECT
    geo_id,
    subregion2_name AS county,
    MAX(population) AS population,
    SUM(new_confirmed) AS total_cases_2020,
    SUM(new_deceased) AS total_deaths_2020,
    SAFE_DIVIDE(SUM(new_confirmed), MAX(population)) * 100000 AS cases_per_100k,
    SAFE_DIVIDE(SUM(new_deceased), MAX(population)) * 100000 AS deaths_per_100k,
  FROM `hcdata1.covid_analysis.ca_covid_2020_view`
  WHERE geo_id IS NOT NULL AND subregion2_name IS NOT NULL
  GROUP BY geo_id, subregion2_name
),

-- Combine COVID with raw healthcare and SDOH metrics, reduces redundant JOINs
combined AS (
  SELECT
    c.*,
    sdoh.POS_TOT_HOSP_ED,
    sdoh.HIFLD_UC,
    sdoh.HIFLD_UC_RATE * 100 AS HIFLD_UC_RATE,
    sdoh.AHRF_HOSP_BED_RATE * 100 AS AHRF_HOSP_BED_RATE,
    sdoh.AHRF_PHYS_PRIMARY_RATE * 100 AS AHRF_PHYS_PRIMARY_RATE,
    sdoh.POS_HOSP_ED_RATE * 100 AS POS_HOSP_ED_RATE,
    sdoh.HIFLD_MEDIAN_DIST_UC,
    sdoh.SAIPE_MEDIAN_HH_INCOME,
    sdoh.ACS_PCT_AGE_ABOVE65,
    sdoh.CHR_PCT_DIABETES,
    sdoh.CHR_PCT_ADULT_OBESITY,
    sdoh.SAIPE_PCT_POV,
    sdoh.SAHIE_PCT_UNINSURED64,
    (
      sdoh.ACS_PCT_AGE_ABOVE65 * 0.4 +
      sdoh.CHR_PCT_DIABETES * 0.25 +
      sdoh.CHR_PCT_ADULT_OBESITY * 0.15 +
      sdoh.SAIPE_PCT_POV * 0.1 +
      sdoh.SAHIE_PCT_UNINSURED64 * 0.1
    ) AS risk_score,
    sdoh.CEN_POPDENSITY_COUNTY,
    sdoh.CDCSVI_RPL_THEME1_SOCIECO,
    sdoh.CDCSVI_RPL_THEME2_HH_COMP,
    sdoh.CDCSVI_RPL_THEME3_MINO,
    sdoh.CDCSVI_RPL_THEMES_ALL
  FROM covid_agg c
  LEFT JOIN `hcdata1.covid_analysis.ahrq_clh_data` sdoh
    ON c.geo_id = LPAD(CAST(sdoh.COUNTYFIPS AS STRING), 5, '0')
),

-- Healthcare infrastructure metrics
healthcare_enriched AS (
  SELECT
    geo_id,
    POS_TOT_HOSP_ED AS total_ed_hospitals,
    HIFLD_UC AS total_urgent_care,
    HIFLD_UC_RATE AS urgent_care_per_100k,
    AHRF_HOSP_BED_RATE AS beds_per_100k,
    AHRF_PHYS_PRIMARY_RATE AS primary_care_physicians_per_100k,
    POS_HOSP_ED_RATE AS ed_hospitals_per_100k,
    HIFLD_MEDIAN_DIST_UC AS median_urgent_care_dist
  FROM combined
),

-- Socio-demographic and risk factors
socio_enriched AS (
  SELECT
    geo_id,
    SAIPE_MEDIAN_HH_INCOME AS median_hh_income,
    ACS_PCT_AGE_ABOVE65 AS percent_elderly,
    CHR_PCT_DIABETES AS percent_diabetes,
    CHR_PCT_ADULT_OBESITY AS percent_obesity,
    SAIPE_PCT_POV AS percent_poverty,
    SAHIE_PCT_UNINSURED64 AS percent_uninsured,
    (
      ACS_PCT_AGE_ABOVE65 * 0.4 +
      CHR_PCT_DIABETES * 0.25 +
      CHR_PCT_ADULT_OBESITY * 0.15 +
      SAIPE_PCT_POV * 0.1 +
      SAHIE_PCT_UNINSURED64 * 0.1
    ) AS risk_score
  FROM combined
),

-- Structural metrics and social vulnerability indices
structural_enriched AS (
  SELECT
    geo_id,
    CEN_POPDENSITY_COUNTY AS pop_density,
    CDCSVI_RPL_THEME1_SOCIECO AS svi_socioeconomic,
    CDCSVI_RPL_THEME2_HH_COMP AS svi_household,
    CDCSVI_RPL_THEME3_MINO AS svi_minority,
    CDCSVI_RPL_THEMES_ALL AS svi_overall
  FROM combined
)

-- Final SELECT/VIEW for Excel/BI
SELECT
  -- COVID metrics
  h.geo_id AS geo_id,
  h.county AS county,
  h.population AS population,
  ROUND(h.total_cases_2020, 0) AS total_cases_2020,
  ROUND(h.total_deaths_2020, 0) AS total_deaths_2020,
  ROUND(h.cases_per_100k, 2) AS cases_per_100k,
  ROUND(h.deaths_per_100k, 2) AS deaths_per_100k,

  -- Healthcare metrics
  hc.total_ed_hospitals AS total_ed_hospitals,
  hc.total_urgent_care AS total_urgent_care,
  ROUND(hc.urgent_care_per_100k, 2) AS urgent_care_per_100k,
  ROUND(hc.beds_per_100k, 2) AS beds_per_100k,
  ROUND(hc.primary_care_physicians_per_100k, 2) AS primary_care_physicians_per_100k,
  ROUND(hc.ed_hospitals_per_100k, 2) AS ed_hospitals_per_100k,
  ROUND(hc.median_urgent_care_dist, 2) AS median_urgent_care_dist,

  -- Socioeconomic and health risks metrics
  ROUND(s.median_hh_income, 2) AS median_hh_income,
  ROUND(s.percent_elderly, 2) AS percent_elderly,
  ROUND(s.percent_diabetes, 2) AS percent_diabetes,
  ROUND(s.percent_obesity, 2) AS percent_obesity,
  ROUND(s.percent_poverty, 2) AS percent_poverty,
  ROUND(s.percent_uninsured, 2) AS percent_uninsured,
  ROUND(s.risk_score, 2) AS risk_score,

  -- Structural and SVI metrics
  ROUND(st.pop_density, 2) AS pop_density,
  ROUND(st.svi_socioeconomic, 2) AS svi_socioeconomic,
  ROUND(st.svi_household, 2) AS svi_household,
  ROUND(st.svi_minority, 2) AS svi_minority,
  ROUND(st.svi_overall, 2) AS svi_overall
FROM covid_agg h
LEFT JOIN healthcare_enriched hc ON h.geo_id = hc.geo_id
LEFT JOIN socio_enriched s ON h.geo_id = s.geo_id
LEFT JOIN structural_enriched st ON h.geo_id = st.geo_id
ORDER BY h.population DESC