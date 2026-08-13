# PostgreSQL Staging & Production Backup & Restore Guide

## 1. Pre-Migration Logical Backup (`pg_dump`)

Prior to executing any DDL schema change or migration on staging/production PostgreSQL:

```bash
# 1. Export binary custom-format backup with timestamp
pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME -Fc -f "hr_app_db_backup_$(date +%Y%m%d_%H%M%S).dump"

# 2. Verify backup file size and integrity
ls -lh hr_app_db_backup_*.dump
```

## 2. Restore Steps (`pg_restore`)

If a migration fails or data integrity verification fails during staging testing:

```bash
# 1. Terminate active database connections
psql -h $DB_HOST -U $DB_USER -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB_NAME' AND pid <> pg_backend_pid();"

# 2. Restore from custom-format backup
pg_restore -h $DB_HOST -U $DB_USER -d $DB_NAME --clean --if-exists "hr_app_db_backup_TIMESTAMP.dump"
```

## 3. Post-Restore Verification
```sql
SELECT count(*) FROM "User";
SELECT count(*) FROM "Payslip";
SELECT count(*) FROM "Kpi";
```
