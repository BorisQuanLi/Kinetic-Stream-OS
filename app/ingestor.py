import os
import time
from dotenv import load_dotenv
from sqlalchemy import create_engine, event

load_dotenv()

# Use safe defaults for production stability
user = os.getenv('DB_USER', 'sa')
pw = os.getenv('DB_PASS')
host = os.getenv('DB_HOST', 'localhost')
db = os.getenv('DB_NAME', 'master')

# 1. High-Performance Engine Configuration
connection_url = f"mssql+pyodbc://{user}:{pw}@{host}:1433/{db}?driver=ODBC+Driver+18+for+SQL+Server&Encrypt=no"
engine = create_engine(connection_url, fast_executemany=True) # Newer SQLAlchemy supports this natively

def simulate_site_ingestion(rows=250000):
    import pandas as pd
    import numpy as np
    
    print(f"📊 Generating {rows} rows of 50-column telemetry...")
    
    # Fast NumPy generation for 50 columns
    data = np.random.standard_normal((rows, 50))
    cols = [f'sensor_{i:02d}' for i in range(50)]
    df = pd.DataFrame(data, columns=cols)
    
    print(f"📡 [INGEST] Streaming to MSSQL...")
    start_time = time.time()
    
    # CRITICAL: Ensure the engine actually connects
    with engine.begin() as connection:
        df.to_sql('Site_Telemetry_Raw', connection, if_exists='append', index=False, chunksize=5000)
    
    duration = time.time() - start_time
    print(f"✅ SUCCESS: Ingested {rows} rows in {duration:.2f} seconds.")

if __name__ == "__main__":
    print("🚀 [BOOT] Kinetic-Stream-OS Ingestor v1.0 starting...")
    
    # Pre-flight: Test connection before generating data
    try:
        with engine.connect() as conn:
            print("✔ Database Connection: Verified")
    except Exception as e:
        print(f"🚨 [FATAL] Database Authentication Failed: {e}")
        exit(1)
    # Database Context Warning
    if db == 'master':
        print("⚠️  [DEMO MODE] Ingesting into 'master' system database for zero-config startup.")
    else:
        print(f"✔ Target Database: {db}")

    # Execute the ingestion engine to stream 250k rows into 'Site_Telemetry_Raw'
    try:
        # Execution with timing
        start_wall_clock = time.time()

        # Proceed with ingestion
        simulate_site_ingestion(rows=250000)
        
        total_time = time.time() - start_wall_clock
        print(f"🏁 [COMPLETE] System idle. Total wall time: {total_time:.2f}s")
        
    except Exception as e:
        # 3. Defensive Error Handling
        print(f"🚨 [FATAL] Ingestion pipeline collapsed: {e}")
        exit(1) # Return non-zero for CI/CD / Jenkins pipelines
