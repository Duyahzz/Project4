import subprocess

cmd = [
    "sqlcmd", "-S", "localhost,1433", "-U", "sa", "-P", "1",
    "-d", "eStudentDB", "-Q",
    "SELECT tp.name AS TABLE_NAME, cp.name AS COLUMN_NAME, tr.name AS REFERENCED_TABLE_NAME FROM sys.foreign_keys fk INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id INNER JOIN sys.tables tp ON fkc.parent_object_id = tp.object_id INNER JOIN sys.columns cp ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id INNER JOIN sys.tables tr ON fkc.referenced_object_id = tr.object_id FOR JSON PATH;",
    "-y", "0", "-w", "8000"
]
res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
print("Exit code:", res.returncode)
print("Stdout len:", len(res.stdout))
print("Stdout:", repr(res.stdout))
print("Stderr:", repr(res.stderr))
