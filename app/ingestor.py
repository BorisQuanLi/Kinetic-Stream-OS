import pandas as pd
import numpy as np
from sqlalchemy import create_engine, event

# 1. High-Performance Engine Configuration
connection_url = "mssql+pyodbc://sa:YourPassword@localhost:1433/master?driver=ODBC+Driver+18+for+SQL+Server&Encrypt=no"
engine = create_engine(connection_url)

# 2. Critical for TB-scale: Enable Fast Execute Many
@event.listens_for(engine, "before_cursor_execute")
def receive_before_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    if executemany:
        cursor.fast_executemany = True

def simulate_site_ingestion(rows=250000):
    # Logic for 50-column dataframe generation...
    # (Use the NumPy logic we discussed)
    df.to_sql('Site_Telemetry_Raw', engine, if_exists='append', index=False, chunksize=5000)
