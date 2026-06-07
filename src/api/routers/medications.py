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

@router.get("/top")
def get_top_medications():
    """returns top 10 most commonly prescribed medications"""
    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT medication_name, medication_code,
               total_prescriptions, total_active,
               patients_prescribed, active_rate_pct,
               prescription_rank
        FROM MART_MEDICATION_COST
        WHERE prescription_rank <= 10
        ORDER BY prescription_rank
    """)
    rows = cursor.fetchall()
    columns = [desc[0] for desc in cursor.description]
    cursor.close()
    conn.close()
    return [dict(zip(columns, row)) for row in rows]

@router.get("/adherence")
def get_medication_adherence():
    """returns medication adherence rates by patient segment"""
    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT segment_type, segment_value,
               patients_in_group, adherent_count,
               adherence_pct, avg_active_rate_pct,
               avg_unique_medications
        FROM MART_ADHERENCE_SUMMARY
        ORDER BY segment_type, adherence_pct DESC
    """)
    rows = cursor.fetchall()
    columns = [desc[0] for desc in cursor.description]
    cursor.close()
    conn.close()
    return [dict(zip(columns, row)) for row in rows]

@router.get("/all")
def get_all_medications():
    """returns all medication prescription statistics"""
    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT medication_name, medication_code,
               total_prescriptions, total_active,
               patients_prescribed, active_rate_pct,
               prescription_rank
        FROM MART_MEDICATION_COST
        ORDER BY prescription_rank
    """)
    rows = cursor.fetchall()
    columns = [desc[0] for desc in cursor.description]
    cursor.close()
    conn.close()
    return [dict(zip(columns, row)) for row in rows]