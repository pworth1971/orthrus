#!/bin/bash
# db_check.sh — show row counts and sizes for all tables in each listed database (no 'column' dependency)

set -euo pipefail

USER="postgres"
HOST="localhost"
PORT="5432"
PASSWORD="Rafter9876!@"

DATABASES=("cadets_e3" "clearscope_e3" "optc_051" "optc_201" "optc_501" "theia_e3")

for DB in "${DATABASES[@]}"; do
  echo "==============================="
  echo "📊 Row counts for database: $DB"
  echo "==============================="

  # Run query and format results manually
  PGPASSWORD="$PASSWORD" psql -U "$USER" -h "$HOST" -p "$PORT" -d "$DB" -X -q -t -c "
    SELECT
      c.relname AS table_name,
      pg_size_pretty(pg_total_relation_size(c.oid)) AS table_size,
      TO_CHAR(c.reltuples::bigint, '999,999,999') AS estimated_rows
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind = 'r'
    ORDER BY c.reltuples DESC;
  " | awk '
    BEGIN {
      printf("%-40s %-10s %-15s\n", "Table Name", "Size", "Estimated Rows");
      printf("%-40s %-10s %-15s\n", "----------------------------------------", "----------", "---------------");
    }
    NF {
      printf("%-40s %-10s %-15s\n", $1, $2, $3);
    }
  '

  echo ""
done

echo "✅ Database table size and row count check complete."
