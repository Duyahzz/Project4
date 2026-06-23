import subprocess
import json

def run_query(sql):
    cmd = [
        "sqlcmd", "-S", "localhost,1433", "-U", "sa", "-P", "1",
        "-d", "eStudentDB", "-Q", sql, "-y", "0", "-w", "8000"
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
    return result.stdout

tables = [
    "Users", "Students", "Teachers", "Parents", "Classes", 
    "TimetableSlots", "LessonSessions", "AttendanceRecords", 
    "Assessments", "StudentMarks"
]

schema = {}
for table in tables:
    sql = f"""
    SELECT 
        COLUMN_NAME, 
        DATA_TYPE, 
        CHARACTER_MAXIMUM_LENGTH, 
        IS_NULLABLE, 
        COLUMN_DEFAULT
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = '{table}'
    ORDER BY ORDINAL_POSITION;
    """
    out = run_query(sql)
    schema[table] = out

with open("scratch/db_schema_details.txt", "w", encoding="utf-8") as f:
    for table, details in schema.items():
        f.write(f"=== TABLE: {table} ===\n")
        f.write(details)
        f.write("\n\n")

print("Schema details written to scratch/db_schema_details.txt")
