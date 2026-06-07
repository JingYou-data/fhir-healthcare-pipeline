# FHIR Healthcare Analytics Pipeline

Clinical Intelligence Platform — dbt Cloud · Snowflake · FastAPI · Power BI

---

## Overview

An end-to-end healthcare analytics engineering pipeline that ingests synthetic FHIR R4 patient data, transforms it through a medallion architecture, exposes clinical KPIs via a REST API, and surfaces insights through an interactive Power BI dashboard.

Built to demonstrate the full Analytics Engineer stack: from raw FHIR JSON ingestion through Bronze → Silver → Gold layers to FastAPI and Power BI — across 253,418 rows of synthetic patient records.

Business impact: the pipeline identifies 30-day readmission risk, medication adherence rates, and top chronic condition prevalence across 1,188 synthetic patients, enabling care coordinators to prioritize outreach and optimize population health management.

---

## Architecture

```
Synthea FHIR R4 JSON (1,188 patients)
Patients · Encounters · Conditions · Medications
        |
        v
Python 3.12 FHIR Parser
PUT + COPY INTO → Snowflake BRONZE schema (253,418 rows)
        |
        v
dbt Cloud — Silver Layer
  staging/       4 views  — type casting, field mapping
  intermediate/  2 tables — 30-day readmission windows, medication adherence
        |
        v
dbt Cloud — Gold Layer
  marts/  7 tables — clinical KPIs
        |
        +---------------------------+
        |                           |
        v                           v
FastAPI (9 endpoints)          Power BI Dashboard
Clinical data query layer      3-page clinical report
```

---

## Tech Stack

1. **Data Generation** — Synthea (MIT): synthetic FHIR R4 patient records
2. **Ingestion** — Python 3.12: FHIR JSON parsing and Snowflake loading via PUT + COPY INTO
3. **Warehouse** — Snowflake: primary analytical store, medallion architecture
4. **Staging** — dbt Cloud views: Silver layer, type casting and field mapping
5. **Intermediate** — dbt Cloud tables: clinical logic, readmission windows and adherence calculation
6. **Marts** — dbt Cloud tables: Gold layer, business-ready clinical metrics
7. **Data Quality** — 19 dbt tests: schema validation and business rules
8. **API** — FastAPI + Uvicorn: clinical data query layer
9. **Visualization** — Power BI: clinical operations dashboard

---

## Data Volume

| Table | Rows | Description |
|-------|------|-------------|
| patients | 1,188 | Synthetic patient demographics |
| encounters | 73,995 | Clinical visit records |
| conditions | 44,273 | Diagnosis and condition records |
| medications | 133,962 | Medication order records |
| Total | 253,418 | Across 4 Bronze tables |

---

## dbt Model Structure

```
models/
├── staging/                          # Silver — FHIR field mapping (views)
│   ├── stg_patients.sql              # Demographics + age calculation
│   ├── stg_encounters.sql            # Visit records + duration_minutes
│   ├── stg_conditions.sql            # Diagnoses + onset/recorded dates
│   ├── stg_medications.sql           # Medication orders + active status
│   ├── sources.yml                   # Source definitions (BRONZE schema)
│   └── schema.yml                    # 19 dbt tests
│
├── intermediate/                     # Silver — Clinical business logic (tables)
│   ├── int_readmission_windows.sql   # 30-day readmission window logic
│   └── int_medication_adherence.sql  # PDC-based adherence calculation
│
└── marts/                            # Gold — Business-ready metrics (tables)
    ├── mart_patient_summary.sql      # Demographics + age group segmentation
    ├── mart_encounter_stats.sql      # Visit counts by type per patient
    ├── mart_encounter_analysis.sql   # Encounter class breakdown
    ├── mart_condition_prevalence.sql # Disease prevalence ranking
    ├── mart_medication_cost.sql      # Top medications by prescription count
    ├── mart_readmission_risk.sql     # 30-day readmission risk by patient
    └── mart_adherence_summary.sql    # Medication adherence by segment
```

---

## Key Clinical Metrics

1. **30-Day Readmission Risk** — patients readmitted within 30 days of discharge; mapped to CMS quality benchmark
2. **Medication Adherence Rate** — percentage of prescriptions remaining active, used as a PDC proxy for chronic disease management
3. **Condition Prevalence** — percentage of patients with each diagnosis, ranked for population health planning
4. **Encounter Duration** — mean visit length in minutes by encounter class, used for resource allocation
5. **Age Group Distribution** — patients segmented into 0-17, 18-34, 35-49, 50-64, 65+ for demographic analysis

---

## FastAPI Clinical Endpoints

```
GET  /patients/high-risk      patients with readmission history, ordered by count
GET  /patients/summary        demographics by age group and gender
GET  /patients/adherence      medication adherence summary by segment
GET  /diagnostics/summary     top 10 conditions by patient prevalence
GET  /diagnostics/all         full condition prevalence ranking
GET  /medications/top         top 10 medications by prescription count
GET  /medications/adherence   adherence rate by age group and gender
GET  /medications/all         all medications with prescription stats
GET  /health                  pipeline health check
```

Interactive API docs: http://127.0.0.1:8000/docs

---

## Data Quality

19 dbt tests across 4 staging models:

1. **unique + not_null** on all primary keys — referential integrity
2. **accepted_values** on gender field — domain validation
3. **relationships** on encounters.patient_id → patients.patient_id — cross-table consistency
4. **not_null with severity: warn** on medication_code — ~19% null rate is expected in FHIR R4 when using contained medication resources; flagged as a warning rather than a hard failure as an intentional data quality design decision

---

## Engineering Challenges and Solutions

Real problems encountered and resolved during the build:

1. **Snowflake account format** — `EH27501` is the org ID, not the account ID; correct format is `OTWSNGO-TK34598`
2. **Reserved keywords** — `start`, `stop`, `end`, and `rows` are Snowflake reserved words; resolved by wrapping in double quotes in DDL and dbt models
3. **VARCHAR length mismatch** — FHIR timestamps like `2013-08-11T23:21:18-05:00` exceeded VARCHAR(20); expanded all date fields to VARCHAR(50)
4. **COPY INTO skipping files** — Snowflake tracks loaded files and skips re-runs; resolved by adding `FORCE = TRUE`
5. **Column count mismatch** — `_loaded_at` is auto-populated, so the CSV column count is one less than the table; resolved by adding `ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE`
6. **dbt test syntax deprecation** — dbt Fusion 2.0 changed the syntax for `accepted_values` and `relationships`; migrated to the `arguments:` block format
7. **Duplicate data on reload** — the loader ran multiple times without truncating; resolved by adding `TRUNCATE TABLE` before each reload
8. **Git root misconfigured** — `.git` was initialized in `C:/Users/jingl` instead of the project root; removed the root `.git` and re-initialized in the correct directory
9. **Large files in git history** — FHIR JSON files and `synthea.jar` were accidentally committed; purged using `git filter-repo`
10. **API credentials exposed** — `.env` was committed to GitHub; rotated Snowflake credentials immediately and purged the file from git history

---

## AI-Assisted Development

This project was built with Claude (Anthropic) and GitHub Copilot as development accelerators, with all output reviewed by the engineer before use.

Where AI was used:

1. **dbt staging model boilerplate** — GitHub Copilot generated initial SQL; schema validation and FHIR field mapping reviewed manually (~2 hours saved)
2. **FHIR R4 JSON flattening logic** — Claude drafted the parser structure; edge cases including missing fields and nested arrays were tested and patched manually (~3 hours saved)
3. **dbt test YAML scaffolding** — GitHub Copilot generated test structure; business rules defined by the engineer, not AI (~1 hour saved)
4. **SQL window functions for readmission logic** — Claude drafted the 30-day window query; validated against CMS readmission definition (~1 hour saved)
5. **FastAPI endpoint stubs** — Claude generated route structure; clinical logic and error handling written manually (~1.5 hours saved)
6. **Snowflake DDL debugging** — Claude identified reserved keyword conflicts; fixes verified and applied manually (~1 hour saved)

Total estimated time saved: approximately 9.5 hours.

Engineering principles followed: all AI-generated SQL was reviewed against the FHIR R4 specification; business metric definitions were written by the engineer with AI handling syntax only; no PHI was included in any prompts — only schema structure and field names were shared with AI tools.

---

## Power BI Dashboard

Three-page clinical operations dashboard:

**Page 1: Population Overview** — complete
- KPI cards: Total Patients, Total Encounters, Avg Visit Duration
- Top 10 conditions by patient prevalence (bar chart)
- Patient age distribution (donut chart)
- Patient gender distribution (pie chart)

**Page 2: Readmission Risk** — in progress
- High-risk patient breakdown by age group
- 30-day readmission rate analysis
- Risk level distribution

**Page 3: Medication and Adherence** — in progress
- Top 10 medications by prescription count
- Adherence rate by age group and gender
- Active vs stopped prescription breakdown

---

## Project Setup

Prerequisites: Python 3.12+, Snowflake account (free trial), dbt Cloud account (free Developer plan), Java 21+ for Synthea, Power BI Desktop.

**1. Generate synthetic data**
```bash
git clone https://github.com/synthetichealth/synthea.git
cd synthea
./run_synthea -p 1000 --exporter.fhir.export=true
```

**2. Install Python dependencies**
```bash
pip install -r requirements.txt
```

**3. Configure environment**
```bash
cp .env.example .env
# Fill in Snowflake credentials
```

**4. Run ingestion pipeline**
```bash
python src/ingestion/fhir_parser.py
python src/ingestion/snowflake_loader.py
```

**5. Run dbt transformations**
```bash
dbt run --select staging
dbt run --select intermediate
dbt run --select marts
dbt test --select staging
```

**6. Start FastAPI server**
```bash
cd src/api
uvicorn main:app --reload
# API docs at http://127.0.0.1:8000/docs
```

---

## Repository Structure

```
fhir-healthcare-pipeline/
├── README.md
├── requirements.txt
├── .env.example
├── .gitignore
│
├── src/
│   ├── ingestion/
│   │   ├── fhir_parser.py
│   │   └── snowflake_loader.py
│   └── api/
│       ├── main.py
│       └── routers/
│           ├── patients.py
│           ├── conditions.py
│           └── medications.py
│
├── models/
│   ├── staging/
│   ├── intermediate/
│   └── marts/
│
└── dashboards/
    └── FHIR_Healthcare_Analytics_Dashboard.pbix
```

---

## Status

| Component | Status |
|-----------|--------|
| Synthea data generation (1,188 patients) | Complete |
| FHIR R4 JSON parser | Complete |
| Snowflake Bronze layer (253,418 rows) | Complete |
| dbt Silver staging models (4 views) | Complete |
| dbt intermediate models (2 tables) | Complete |
| dbt Gold marts (7 tables) | Complete |
| dbt tests (19 tests, 18 pass / 1 warn) | Complete |
| FastAPI clinical query layer (9 endpoints) | Complete |
| Power BI Page 1: Population Overview | Complete |
| Power BI Page 2: Readmission Risk | In Progress |
| Power BI Page 3: Medication and Adherence | In Progress |

---

## Author

Jing You — Analytics Engineer
Nashville Software School, Data Engineering Graduate, May 2026
10 years business operations experience across e-commerce, hospitality, and retail analytics

GitHub: github.com/JingYou-data
LinkedIn: linkedin.com/in/jingyou84
---
Synthetic patient data generated by Synthea (MIT License). No real patient data used.
FHIR is a registered trademark of HL7.