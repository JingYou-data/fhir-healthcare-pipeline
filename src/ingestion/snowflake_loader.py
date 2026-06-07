import snowflake.connector
import os
from dotenv import load_dotenv

load_dotenv()

conn = snowflake.connector.connect(
    account=os.getenv("SNOWFLAKE_ACCOUNT"),
    user=os.getenv("SNOWFLAKE_USER"),
    password=os.getenv("SNOWFLAKE_PASSWORD"),
    warehouse=os.getenv("SNOWFLAKE_WAREHOUSE"),
    database="HEALTHCARE_DB",
    schema="BRONZE"
)

cursor = conn.cursor()

csv_files = [
    ("patients",    r"output\parsed\patients.csv"),
    ("encounters",  r"output\parsed\encounters.csv"),
    ("conditions",  r"output\parsed\conditions.csv"),
    ("medications", r"output\parsed\medications.csv"),
]

for table, filepath in csv_files:
    print(f"uploading {filepath} → @FHIR_STAGE...")
    cursor.execute(f"PUT file://{os.path.abspath(filepath)} @BRONZE.FHIR_STAGE AUTO_COMPRESS=TRUE OVERWRITE=TRUE")
    print(f"{table} complete!")

    print(f"loading {table} → BRONZE.{table}...")
    cursor.execute(f"""
        COPY INTO BRONZE.{table}
        FROM @BRONZE.FHIR_STAGE/{table}.csv.gz
        FILE_FORMAT = (
            TYPE = 'CSV'
            SKIP_HEADER = 1
            FIELD_OPTIONALLY_ENCLOSED_BY = '"'
            NULL_IF = ('', 'NULL', 'null')
            ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
        )
        FORCE = TRUE
        ON_ERROR = 'CONTINUE';
    """)
    print(f" {table} complete!")

cursor.close()
conn.close()
print("\n complete!")