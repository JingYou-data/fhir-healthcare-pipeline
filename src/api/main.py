from fastapi import FastAPI
from routers import patients, conditions, medications
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(
    title="FHIR Healthcare Analytics API",
    description="Clinical data query layer for FHIR Healthcare Analytics Pipeline",
    version="1.0.0"
)

app.include_router(patients.router, prefix="/patients", tags=["Patients"])
app.include_router(conditions.router, prefix="/diagnostics", tags=["Diagnostics"])
app.include_router(medications.router, prefix="/medications", tags=["Medications"])

@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "pipeline": "FHIR Healthcare Analytics",
        "warehouse": "Snowflake HEALTHCARE_DB",
        "gold_layer": "DBT_JYOU_GOLD"
    }