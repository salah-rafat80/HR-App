# Per-Table Decimal Monetary Data-Impact Analysis

## 1. Precision & Currency Policy
- **Type**: `Decimal(12, 2)` (`NUMERIC(12, 2)`)
- **Scale**: 2 decimal places (cents / minor units)
- **Maximum Representable Value**: `9,999,999,999.99` (up to 10 billion currency units)
- **Rounding Strategy**: Bank's rounding (`HALF_EVEN`) for intermediate tax and allowance calculations.

## 2. Table-by-Table Data Impact Assessment

### A. Table `"PayrollRun"`
- **Column Affected**: `totalAmount`
- **Original Type**: `DOUBLE PRECISION` (`Float`)
- **New Type**: `DECIMAL(12, 2)`
- **Conversion Expression**: `USING "totalAmount"::numeric(12,2)`
- **Data Impact Risk**: Zero data loss for non-fractional or 2-decimal values. Floating-point values with floating binary artifacts (e.g. `1250.0000000000002`) are truncated cleanly to `1250.00`.

### B. Table `"Payslip"`
- **Columns Affected**: `baseSalary`, `netPay`
- **Original Type**: `DOUBLE PRECISION` (`Float`)
- **New Type**: `DECIMAL(12, 2)`
- **Conversion Expression**: `USING "baseSalary"::numeric(12,2)`, `USING "netPay"::numeric(12,2)`
- **Data Impact Risk**: None. Replaces binary float approximations with exact decimal representations.

### C. Table `"PayslipLineItem"`
- **Column Affected**: `amount`
- **Original Type**: `DOUBLE PRECISION` (`Float`)
- **New Type**: `DECIMAL(12, 2)`
- **Conversion Expression**: `USING "amount"::numeric(12,2)`
- **Data Impact Risk**: None. Guarantees that line-item additions equal `netPay` without cent rounding errors.

### D. Table `"BonusNotice"`
- **Column Affected**: `amount`
- **Original Type**: `DOUBLE PRECISION` (`Float`)
- **New Type**: `DECIMAL(12, 2)`
- **Conversion Expression**: `USING "amount"::numeric(12,2)`
- **Data Impact Risk**: None.

## 3. Staging Verification Queries

```sql
-- 1. Check for any out-of-range monetary values prior to migration
SELECT id, "totalAmount" FROM "PayrollRun" WHERE "totalAmount" > 9999999999.99;
SELECT id, "baseSalary", "netPay" FROM "Payslip" WHERE "baseSalary" > 9999999999.99 OR "netPay" > 9999999999.99;

-- 2. Verify precision conversion post-migration
SELECT id, "baseSalary", pg_typeof("baseSalary") FROM "Payslip" LIMIT 5;
```
