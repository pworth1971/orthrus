#!/bin/bash
set -euo pipefail

USER="postgres"
HOST="localhost"
PORT="5432"
PASSWORD="Rafter9876!@"
DB_NAME="cadets_e3"
DUMP_PATH="../data/cadets_e3.dump"

echo "==============================================="
echo "🔁 Reloading database '$DB_NAME' from $DUMP_PATH"
echo "==============================================="

# -----------------------------------------------------------------------------
# Step 1: Drop database (if exists) completely
# -----------------------------------------------------------------------------
echo "🗑️  Dropping existing database (if any)..."
PGPASSWORD="$PASSWORD" psql -U "$USER" -h "$HOST" -p "$PORT" -d postgres -v ON_ERROR_STOP=1 -c \
"DROP DATABASE IF EXISTS \"$DB_NAME\" WITH (FORCE);"
echo "✅ Database '$DB_NAME' dropped (if it existed)."

# -----------------------------------------------------------------------------
# Step 2: Recreate the database owned by postgres
# -----------------------------------------------------------------------------
echo "📦 Creating fresh database '$DB_NAME' owned by $USER..."
PGPASSWORD="$PASSWORD" psql -U "$USER" -h "$HOST" -p "$PORT" -d postgres -v ON_ERROR_STOP=1 -c \
"CREATE DATABASE \"$DB_NAME\" OWNER $USER;"
echo "✅ Database '$DB_NAME' created."

# -----------------------------------------------------------------------------
# Step 3: Restore the dump file into the database
# -----------------------------------------------------------------------------
echo "📥 Restoring from dump file..."
# Use --clean and --if-exists to remove existing objects if dump has schema
# If dump lacks CREATE DATABASE, we target -d "$DB_NAME" instead of -d postgres
PGPASSWORD="$PASSWORD" pg_restore \
  --clean --if-exists \
  --no-owner --no-privileges \
  -U "$USER" -h "$HOST" -p "$PORT" \
  -d "$DB_NAME" "$DUMP_PATH"

echo "✅ Restore completed for '$DB_NAME'."

# -----------------------------------------------------------------------------
# Step 4: Verify results
# -----------------------------------------------------------------------------
echo "🔎 Verifying ownership and tables..."
PGPASSWORD="$PASSWORD" psql -U "$USER" -h "$HOST" -p "$PORT" -d "$DB_NAME" -v ON_ERROR_STOP=1 -c \
"SELECT datname, pg_catalog.pg_get_userbyid(datdba) AS owner FROM pg_database WHERE datname = '$DB_NAME';"

PGPASSWORD="$PASSWORD" psql -U "$USER" -h "$HOST" -p "$PORT" -d "$DB_NAME" -q -c "\dt" || true

echo "==============================================="
echo "🎉 Database '$DB_NAME' successfully reloaded and owned by $USER"
echo "==============================================="
