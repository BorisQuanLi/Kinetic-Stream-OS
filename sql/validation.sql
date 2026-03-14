-- sql/validation.sql: Relational parity check for Kinetic-Stream-OS
-- Purpose: Verify 250k-row grain integrity before final commit

DECLARE @ExpectedCount INT = 250000;
DECLARE @ActualCount INT;

SELECT @ActualCount = COUNT(*) FROM Site_Telemetry_Raw;

PRINT '--- 📊 GRAIN VALIDATION REPORT ---';
PRINT 'Target Row Count: ' + CAST(@ExpectedCount AS VARCHAR);
PRINT 'Actual Row Count: ' + CAST(@ActualCount AS VARCHAR);

-- 1. Check for Row Delta
IF @ActualCount <> @ExpectedCount
BEGIN
    PRINT '🚨 [FAILURE]: Row count mismatch detected.';
    THROW 50000, 'Relational Parity Failure: Row count does not match expected grain.', 1;
END

-- 2. Check for Null Invariants (Ensure critical sensors aren't blank)
IF EXISTS (SELECT 1 FROM Site_Telemetry_Raw WHERE sensor_00 IS NULL OR sensor_49 IS NULL)
BEGIN
    PRINT '🚨 [FAILURE]: Null values detected in mission-critical sensor columns.';
    THROW 50001, 'Data Quality Failure: Incomplete sensor telemetry.', 1;
END

PRINT '✅ [SUCCESS]: Relational parity verified at 250k-row grain.';
