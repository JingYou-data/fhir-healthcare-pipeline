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

@router.get("/summary")
def get_diagnostics_summary():
    """returns top 10 condition prevalence rates"""
    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT condition_code, condition_description,
               affected_patients, total_occurrences,
               prevalence_pct, prevalence_rank
        FROM MART_CONDITION_PREVALENCE
        WHERE prevalence_rank <= 10
        ORDER BY prevalence_rank
    """)
    rows = cursor.fetchall()
    columns = [desc[0] for desc in cursor.description]
    cursor.close()
    conn.close()
    return [dict(zip(columns, row)) for row in rows]

@router.get("/all")
def get_all_conditions():
    """returns all condition prevalence rates"""
    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT condition_code, condition_description,
               affected_patients, total_occurrences,
               total_patients, prevalence_pct, prevalence_rank
        FROM MART_CONDITION_PREVALENCE
        ORDER BY prevalence_rank
    """)
    rows = cursor.fetchall()
    columns = [desc[0] for desc in cursor.description]
    cursor.close()
    conn.close()
    return [dict(zip(columns, row)) for row in rows]