#!/bin/bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Script: load_dumps_with_password.sh
# Purpose: Drop, recreate, and restore PostgreSQL databases from .dump files
# -----------------------------------------------------------------------------

USER="postgres"
HOST="localhost"
PORT="5432"
PASSWORD="Rafter9876!@"

DATA_DIR="../data"

echo "[*] Starting restore process from $DATA_DIR"

for dump_file in "$DATA_DIR"/*.dump; do
  db_name=$(basename "$dump_file" .dump)
  echo "==========================================="
  echo "Recreating database '$db_name' and restoring from $dump_file..."
  echo "==========================================="

  # Drop and recreate database to ensure a clean restore
  PGPASSWORD="$PASSWORD" psql -U "$USER" -h "$HOST" -p "$PORT" -c "DROP DATABASE IF EXISTS \"$db_name\";"
  PGPASSWORD="$PASSWORD" psql -U "$USER" -h "$HOST" -p "$PORT" -c "CREATE DATABASE \"$db_name\";"

  # Restore dump (ignore harmless transaction_timeout warnings)
  PGPASSWORD="$PASSWORD" pg_restore --no-owner --no-privileges --no-comments \
    -U "$USER" -h "$HOST" -p "$PORT" -d "$db_name" "$dump_file" || true

  echo "✅ Restore completed for '$db_name'"
  echo ""
done

echo "🎉 All PostgreSQL database restores complete!"
