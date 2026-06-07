from fastapi import APIRouter
import snowflake.connector
import os
from dotenv import load_dotenv

load_dotenv()

router = APIRouter()

def get_conn():
    return snowflake.connector.connect(
        account=os.getenv("SNOWFLAKE_ACCOUNT"),
        user=os.getenv("SNOWFLAKE_USER"),
        password=os.getenv("SNOWFLAKE_PASSWORD"),
        warehouse=os.getenv("SNOWFLAKE_WAREHOUSE"),
        database="HEALTHCARE_DB",
        schema="DBT_JYOU_GOLD"
    )

@router.get("/high-risk")
def get_high_risk_patients():
    """returns high-risk readmission patients (risk_level = High)"""
    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT patient_id, first_name, last_name, age_years,
               age_group, gender_display, state,
               readmission_count, readmission_rate_pct, risk_level
        FROM MART_READMISSION_RISK
        WHERE readmission_count > 0
        ORDER BY readmission_count DESC
        LIMIT 20
    """)
    rows = cursor.fetchall()
    columns = [desc[0] for desc in cursor.description]
    cursor.close()
    conn.close()
    return [dict(zip(columns, row)) for row in rows]

@router.get("/summary")
def get_patient_summary():
    """returns patient summary statistics by"""
    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT age_group, gender_display,
               COUNT(*) as patient_count
        FROM MART_PATIENT_SUMMARY
        GROUP BY age_group, gender_display
        ORDER BY age_group, gender_display
    """)
    rows = cursor.fetchall()
    columns = [desc[0] for desc in cursor.description]
    cursor.close()
    conn.close()
    return [dict(zip(columns, row)) for row in rows]

@router.get("/adherence")
def get_adherence_summary():
    """returns medication adherence summary by patient segment"""
    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT segment_type, segment_value,
               patients_in_group, adherent_count,
               adherence_pct, avg_active_rate_pct
        FROM MART_ADHERENCE_SUMMARY
        ORDER BY segment_type, adherence_pct DESC
    """)
    rows = cursor.fetchall()
    columns = [desc[0] for desc in cursor.description]
    cursor.close()
    conn.close()
    return [dict(zip(columns, row)) for row in rows]