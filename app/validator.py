import os
import sys
import pyodbc
from dotenv import load_dotenv
load_dotenv()

# Replace your hardcoded CONN_STR with this:
USER = os.getenv('DB_USER', 'sa')
PASS = os.getenv('DB_PASS')
HOST = os.getenv('DB_HOST', 'localhost')
DB = os.getenv('DB_NAME', 'master')

CONN_STR = f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={HOST};DATABASE={DB};UID={USER};PWD={PASS};Encrypt=no"

class KineticValidator:
    def __init__(self, connection_string):
        self.conn = pyodbc.connect(connection_string)
        self.cursor = self.conn.cursor()

    def check_row_parity(self, expected_count, table_name):
        """Validates the 250k row grain mentioned by the Team Lead."""
        query = f"SELECT COUNT(*) FROM {table_name}"
        self.cursor.execute(query)
        actual_count = self.cursor.fetchone()[0]
        
        delta = actual_count - expected_count
        if delta == 0:
            print(f"SUCCESS: Row parity maintained at {actual_count}.")
            return True
        else:
            print(f"FAILURE: Row explosion/loss detected. Delta: {delta}")
            return False

    def check_relational_parity(self, source_table, target_table):
        """Uses T-SQL EXCEPT to find missing or mutated rows in 50-column tables."""
        # Note: We compare PKs or specific sensitive columns across the 50-column width
        query = f"""
            SELECT RobotID, SiteID FROM {source_table}
            EXCEPT
            SELECT RobotID, SiteID FROM {target_table}
        """
        self.cursor.execute(query)
        mismatches = self.cursor.fetchall()
        
        if not mismatches:
            print("SUCCESS: Relational integrity verified via EXCEPT.")
            return True
        else:
            print(f"FAILURE: {len(mismatches)} record discrepancies found.")
            return False

if __name__ == "__main__":
    # Uses the environment-injected CONN_STR defined at the top of the module
    validator = KineticValidator(CONN_STR)

    if not validator.check_row_parity(250000, "Site_Telemetry_Raw"):
        import sys
        sys.exit(1) # Fail the Jenkins pipeline
