"""Load Synthea CSV data into MySQL (synthea_db)."""

import csv
import os
import pymysql

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTPUT_DIR = os.path.join(BASE_DIR, "output")
SQL_FILE = os.path.join(BASE_DIR, "script", "init_db.sql")

CONN_PARAMS = dict(
    host="127.0.0.1",
    port=3306,
    user="root",
    password="rootpassword",
    charset="utf8mb4",
    autocommit=False,
)

# CSV column name -> DB column name mapping per table.
# Only entries that differ need to be listed.
COLUMN_MAP = {
    "patients": {"FIRST": "first_name", "MIDDLE": "middle_name", "LAST": "last_name"},
    "encounters": {
        "PATIENT": "patient_id",
        "ORGANIZATION": "organization_id",
        "PROVIDER": "provider_id",
        "PAYER": "payer_id",
    },
    "providers": {"ORGANIZATION": "organization_id"},
    "payer_transitions": {
        "PATIENT": "patient_id",
        "MEMBERID": "member_id",
        "PAYER": "payer_id",
    },
    "conditions": {
        "PATIENT": "patient_id",
        "ENCOUNTER": "encounter_id",
    },
    "allergies": {
        "PATIENT": "patient_id",
        "ENCOUNTER": "encounter_id",
    },
    "medications": {
        "PATIENT": "patient_id",
        "PAYER": "payer_id",
        "ENCOUNTER": "encounter_id",
    },
    "procedures": {
        "PATIENT": "patient_id",
        "ENCOUNTER": "encounter_id",
    },
    "observations": {
        "DATE": "date",
        "PATIENT": "patient_id",
        "ENCOUNTER": "encounter_id",
        "VALUE": "value_text",
    },
    "immunizations": {
        "PATIENT": "patient_id",
        "ENCOUNTER": "encounter_id",
    },
    "careplans": {
        "PATIENT": "patient_id",
        "ENCOUNTER": "encounter_id",
    },
    "devices": {
        "PATIENT": "patient_id",
        "ENCOUNTER": "encounter_id",
    },
    "imaging_studies": {
        "Id": "study_id",
        "PATIENT": "patient_id",
        "ENCOUNTER": "encounter_id",
    },
    "supplies": {
        "PATIENT": "patient_id",
        "ENCOUNTER": "encounter_id",
    },
    "claims": {
        "PATIENTID": "patient_id",
        "PROVIDERID": "provider_id",
        "PRIMARYPATIENTINSURANCEID": "primary_patient_insurance_id",
        "SECONDARYPATIENTINSURANCEID": "secondary_patient_insurance_id",
        "DEPARTMENTID": "department_id",
        "PATIENTDEPARTMENTID": "patient_department_id",
        "REFERRINGPROVIDERID": "referring_provider_id",
        "APPOINTMENTID": "appointment_id",
        "CURRENTILLNESSDATE": "current_illness_date",
        "SERVICEDATE": "service_date",
        "SUPERVISINGPROVIDERID": "supervising_provider_id",
        "LASTBILLEDDATE1": "lastbilleddate1",
        "LASTBILLEDDATE2": "lastbilleddate2",
        "LASTBILLEDDATEP": "lastbilleddatep",
        "HEALTHCARECLAIMTYPEID1": "healthcareclaimtypeid1",
        "HEALTHCARECLAIMTYPEID2": "healthcareclaimtypeid2",
    },
    "claims_transactions": {
        "CLAIMID": "claim_id",
        "CHARGEID": "charge_id",
        "PATIENTID": "patient_id",
        "FROMDATE": "from_date",
        "TODATE": "to_date",
        "PLACEOFSERVICE": "place_of_service",
        "PROCEDURECODE": "procedure_code",
        "DIAGNOSISREF1": "diagnosisref1",
        "DIAGNOSISREF2": "diagnosisref2",
        "DIAGNOSISREF3": "diagnosisref3",
        "DIAGNOSISREF4": "diagnosisref4",
        "DEPARTMENTID": "department_id",
        "UNITAMOUNT": "unit_amount",
        "TRANSFEROUTID": "transfer_out_id",
        "TRANSFERTYPE": "transfer_type",
        "APPOINTMENTID": "appointment_id",
        "LINENOTE": "line_note",
        "PATIENTINSURANCEID": "patient_insurance_id",
        "FEESCHEDULEID": "fee_schedule_id",
        "PROVIDERID": "provider_id",
        "SUPERVISINGPROVIDERID": "supervising_provider_id",
    },
}

# Load order respects foreign key dependencies.
LOAD_ORDER = [
    "organizations",
    "payers",
    "patients",
    "providers",
    "encounters",
    "payer_transitions",
    "conditions",
    "allergies",
    "medications",
    "procedures",
    "observations",
    "immunizations",
    "careplans",
    "devices",
    "imaging_studies",
    "supplies",
    "claims",
    "claims_transactions",
]

BATCH_SIZE = 5000


def map_col(table: str, csv_col: str) -> str:
    """Map a CSV column header to the DB column name."""
    tmap = COLUMN_MAP.get(table, {})
    if csv_col in tmap:
        return tmap[csv_col]
    # Default: lowercase
    return csv_col.lower()


import re

_ISO_DT = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$")


def clean_value(val: str):
    """Return None for empty strings, otherwise the stripped value."""
    val = val.strip()
    if val == "":
        return None
    # Convert ISO 8601 datetime (2025-04-14T12:06:13Z) to MySQL format
    if _ISO_DT.match(val):
        return val.replace("T", " ").replace("Z", "")
    return val


def load_table(cursor, table: str):
    csv_path = os.path.join(OUTPUT_DIR, f"{table}.csv")
    if not os.path.exists(csv_path):
        print(f"  SKIP {table} (no CSV)")
        return

    with open(csv_path, "r", encoding="utf-8-sig") as f:
        reader = csv.reader(f)
        csv_headers = next(reader)

    db_cols = [map_col(table, h) for h in csv_headers]

    # For observations, add value_numeric computed column
    extra_numeric = table == "observations"
    if extra_numeric:
        insert_cols = db_cols + ["value_numeric"]
    else:
        insert_cols = db_cols

    placeholders = ", ".join(["%s"] * len(insert_cols))
    col_list = ", ".join(f"`{c}`" for c in insert_cols)
    sql = f"INSERT INTO `{table}` ({col_list}) VALUES ({placeholders})"

    row_count = 0
    batch = []

    with open(csv_path, "r", encoding="utf-8-sig") as f:
        reader = csv.reader(f)
        next(reader)  # skip header
        for row in reader:
            values = [clean_value(v) for v in row]
            if extra_numeric:
                # try to parse value_text as numeric
                vt_idx = db_cols.index("value_text")
                vt = values[vt_idx]
                try:
                    values.append(float(vt) if vt is not None else None)
                except (ValueError, TypeError):
                    values.append(None)
            batch.append(values)
            if len(batch) >= BATCH_SIZE:
                cursor.executemany(sql, batch)
                row_count += len(batch)
                batch = []
        if batch:
            cursor.executemany(sql, batch)
            row_count += len(batch)

    print(f"  {table}: {row_count} rows")


def main():
    # 1. Create schema
    print("Creating schema...")
    conn = pymysql.connect(**CONN_PARAMS)
    cur = conn.cursor()

    with open(SQL_FILE, "r", encoding="utf-8") as f:
        sql_script = f.read()

    # Split on semicolons and execute each statement
    for stmt in sql_script.split(";"):
        stmt = stmt.strip()
        if stmt:
            cur.execute(stmt)
    conn.commit()

    # 2. Load data
    conn.select_db("synthea_db")
    cur = conn.cursor()

    # Disable FK checks for faster loading
    cur.execute("SET FOREIGN_KEY_CHECKS = 0")
    cur.execute("SET unique_checks = 0")

    for table in LOAD_ORDER:
        print(f"Loading {table}...")
        load_table(cur, table)
        conn.commit()

    cur.execute("SET FOREIGN_KEY_CHECKS = 1")
    cur.execute("SET unique_checks = 1")
    conn.commit()

    conn.close()
    print("\nDone! All data loaded into synthea_db.")


if __name__ == "__main__":
    main()
