import json
import os
import pandas as pd
from tqdm import tqdm
from dotenv import load_dotenv

load_dotenv()

FHIR_DIR = os.getenv("FHIR_DIR", "output/fhir")

def extract_patients(bundle: dict) -> dict | None:
    for entry in bundle.get("entry", []):
        resource = entry.get("resource", {})
        if resource.get("resourceType") == "Patient":
            name = resource.get("name", [{}])[0]
            address = resource.get("address", [{}])[0]
            return {
                "patient_id":   resource.get("id"),
                "first_name":   " ".join(name.get("given", [])),
                "last_name":    name.get("family"),
                "birth_date":   resource.get("birthDate"),
                "gender":       resource.get("gender"),
                "city":         address.get("city"),
                "state":        address.get("state"),
                "postal_code":  address.get("postalCode"),
            }
    return None

def extract_encounters(bundle: dict) -> list[dict]:
    rows = []
    for entry in bundle.get("entry", []):
        resource = entry.get("resource", {})
        if resource.get("resourceType") == "Encounter":
            period = resource.get("period", {})
            rows.append({
                "encounter_id":  resource.get("id"),
                "patient_id":    resource.get("subject", {}).get("reference", "").split(":")[-1],
                "start":         period.get("start"),
                "end":           period.get("end"),
                "status":        resource.get("status"),
                "class":         resource.get("class", {}).get("code"),
                "type":          resource.get("type", [{}])[0].get("text"),
            })
    return rows

def extract_conditions(bundle: dict) -> list[dict]:
    rows = []
    for entry in bundle.get("entry", []):
        resource = entry.get("resource", {})
        if resource.get("resourceType") == "Condition":
            code = resource.get("code", {})
            coding = code.get("coding", [{}])[0]
            rows.append({
                "condition_id":   resource.get("id"),
                "patient_id":     resource.get("subject", {}).get("reference", "").split(":")[-1],
                "encounter_id":   resource.get("encounter", {}).get("reference", "").split(":")[-1],
                "code":           coding.get("code"),
                "description":    coding.get("display"),
                "onset_date":     resource.get("onsetDateTime"),
                "recorded_date":  resource.get("recordedDate"),
            })
    return rows

def extract_medications(bundle: dict) -> list[dict]:
    rows = []
    for entry in bundle.get("entry", []):
        resource = entry.get("resource", {})
        if resource.get("resourceType") == "MedicationRequest":
            med = resource.get("medicationCodeableConcept", {})
            coding = med.get("coding", [{}])[0]
            rows.append({
                "medication_id":   resource.get("id"),
                "patient_id":      resource.get("subject", {}).get("reference", "").split(":")[-1],
                "encounter_id":    resource.get("encounter", {}).get("reference", "").split(":")[-1],
                "medication_code": coding.get("code"),
                "medication_name": coding.get("display"),
                "authored_on":     resource.get("authoredOn"),
                "status":          resource.get("status"),
            })
    return rows

def parse_all(fhir_dir: str = FHIR_DIR):
    patients, encounters, conditions, medications = [], [], [], []

    files = [f for f in os.listdir(fhir_dir) if f.endswith(".json")]
    print(f"Found {len(files)} FHIR files\n")

    for filename in tqdm(files, desc="Parsing FHIR bundles"):
        path = os.path.join(fhir_dir, filename)
        with open(path, "r", encoding="utf-8") as f:
            bundle = json.load(f)

        patient = extract_patients(bundle)
        if patient:
            patients.append(patient)

        encounters.extend(extract_encounters(bundle))
        conditions.extend(extract_conditions(bundle))
        medications.extend(extract_medications(bundle))

    return {
        "patients":    pd.DataFrame(patients),
        "encounters":  pd.DataFrame(encounters),
        "conditions":  pd.DataFrame(conditions),
        "medications": pd.DataFrame(medications),
    }

if __name__ == "__main__":
    dfs = parse_all()

    os.makedirs("output/parsed", exist_ok=True)

    for name, df in dfs.items():
        path = f"output/parsed/{name}.csv"
        df.to_csv(path, index=False)
        print(f"{name}: {len(df):,} rows → saved to {path}")