-- Migration: 20260815120000_server_authoritative_egypt_time
-- Description: Convert instant columns to timestamptz(3) and business dates to date.
-- STATUS: UNAPPLIED (Awaiting audit & explicit owner approval. DO NOT EXECUTE DIRECTLY).

/*
===============================================================================
LEGACY DATA AUDIT REQUIRED BEFORE EXECUTION
===============================================================================
- Historical `timestamp without time zone` data lacks stored timezone metadata.
- The old values may represent either UTC wall-clock values or Cairo wall-clock values.
- The correct `USING` expression is different for those two cases.
- A read-only audit must compare representative legacy attendance and overtime records
  against trusted API/audit evidence before choosing a conversion.
- The owner must explicitly approve the interpretation and the final conversion
  expression before any migration is run.

Candidate patterns (EXAMPLES ONLY, NEVER EXECUTABLE SQL IN THIS ARTIFACT):
-- If audit proves legacy values are UTC wall-clock:
-- "column" AT TIME ZONE 'UTC'
--
-- If audit proves legacy values are Cairo wall-clock:
-- "column" AT TIME ZONE 'Africa/Cairo'

Neither candidate pattern may be applied until audit and owner approval.

-------------------------------------------------------------------------------
FUTURE AUDIT CHECKLIST:
-------------------------------------------------------------------------------
- inspect backend write/serialization behavior for each affected column;
- select a limited read-only sample of existing attendance and overtime records;
- compare stored values to trusted request/audit/reference times;
- decide UTC-wall-clock vs Cairo-wall-clock per column;
- write a reviewed, separately approved executable migration;
- take a backup before application.
===============================================================================
*/

-- SCHEMA-INTENT REFERENCE (NON-EXECUTABLE DOCUMENTATION):
-- Target schema maps instant timestamps to TIMESTAMPTZ(3) and business dates to DATE.
-- No ALTER TABLE ... TYPE TIMESTAMPTZ statements with unproven conversions are executed here.
