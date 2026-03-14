-- sql/schema.sql: Relational definition for high-velocity telemetry
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Site_Telemetry_Raw')
BEGIN
    CREATE TABLE Site_Telemetry_Raw (
        -- Primary Key or Identity usually goes here for tracking
        id INT IDENTITY(1,1) PRIMARY KEY,
        timestamp DATETIME DEFAULT GETDATE(),
        sensor_00 FLOAT, sensor_01 FLOAT, sensor_02 FLOAT, sensor_03 FLOAT, sensor_04 FLOAT,
        -- ... [Repeat for all 50 sensors] ...
        sensor_45 FLOAT, sensor_46 FLOAT, sensor_47 FLOAT, sensor_48 FLOAT, sensor_49 FLOAT
    );
    CREATE INDEX IX_Telemetry_Timestamp ON Site_Telemetry_Raw(timestamp);
END
