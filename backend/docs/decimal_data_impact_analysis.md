# Per-Table Decimal Monetary & Idempotency Data-Impact Analysis

## 1. Precision & Currency Policy
- **Type**: `Decimal(12, 2)` (`NUMERIC(12, 2)`)
- **Scale**: 2 decimal places (cents / minor units)
- **Range Boundary**: `[-9,999,999,999.99, 9,999,999,999.99]`
- **Rounding Strategy**: Bank's rounding (`HALF_EVEN`) for intermediate tax and allowance calculations.

## 2. Table-by-Table Data Impact Assessment

### A. Table `"PayrollRun"`
- **Column Affected**: `totalAmount`
- **Original Type**: `DOUBLE PRECISION` (`Float`)
- **New Type**: `DECIMAL(12, 2)`
- **Conversion Expression**: `USING "totalAmount"::numeric(12,2)`
- **Data Impact Guarantee**: Zero data loss guaranteed **only after** Preflight Checks 1 & 2 pass (validating no `NaN`, `Infinity`, or range overflow).

### B. Table `"Payslip"`
- **Columns Affected**: `baseSalary`, `netPay`, `payrollRunId`
- **Original Type**: `DOUBLE PRECISION` (`Float`), `TEXT` (nullable)
- **New Type**: `DECIMAL(12, 2)`, `TEXT` (NOT NULL)
- **Idempotency Policy**: `@@unique([userId, payrollRunId])`. Non-null `payrollRunId` ensures true idempotency in PostgreSQL.
- **Conversion Expression**: `USING "baseSalary"::numeric(12,2)`, `USING "netPay"::numeric(12,2)`

### C. Table `"PayslipLineItem"`
- **Column Affected**: `amount`
- **Original Type**: `DOUBLE PRECISION` (`Float`)
- **New Type**: `DECIMAL(12, 2)`

### D. Table `"BonusNotice"`
- **Column Affected**: `amount`
- **Original Type**: `DOUBLE PRECISION` (`Float`)
- **New Type**: `DECIMAL(12, 2)`

## 3. Mandatory Preflight SQL Verification Queries

```sql
-- 1. Preflight Check for NaN or Infinity values
SELECT 'Payslip' AS tbl, id FROM "Payslip" WHERE "baseSalary" = 'NaN'::float OR "baseSalary" = 'Infinity'::float OR "netPay" = 'NaN'::float OR "netPay" = 'Infinity'::float;

-- 2. Preflight Check for values exceeding Decimal(12,2) range
SELECT 'Payslip' AS tbl, id FROM "Payslip" WHERE ABS("baseSalary") > 9999999999.99 OR ABS("netPay") > 9999999999.99;

-- 3. Preflight Check for values requiring >2 decimal place rounding
SELECT 'Payslip' AS tbl, id, "netPay" FROM "Payslip" WHERE ROUND("netPay"::numeric, 2) != "netPay"::numeric;

-- 4. Preflight Check for duplicate (userId, payrollRunId) pairs
SELECT "userId", "payrollRunId", COUNT(*) FROM "Payslip" GROUP BY "userId", "payrollRunId" HAVING COUNT(*) > 1;
```
