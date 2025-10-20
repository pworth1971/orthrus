#!/bin/bash
set -euo pipefail

USER="postgres"
HOST="localhost"
PORT="5432"
PASSWORD="Rafter9876!@"

# List of datasets (databases)
DATASETS=("clearscope_e3" "cadets_e3" "theia_e3" "clearscope_e5" "cadets_e5" "theia_e5")

echo "==============================================="
echo "🚨 WARNING: This will drop ALL user databases! "
echo "==============================================="

# -----------------------------------------------------------------------------
# Step 1. Drop all existing user databases except system ones
# -----------------------------------------------------------------------------
echo "[*] Dropping all existing user databases..."
PGPASSWORD="$PASSWORD" psql -U "$USER" -h "$HOST" -p "$PORT" -d postgres -Atc \
"SELECT datname FROM pg_database WHERE datistemplate = false AND datname NOT IN ('postgres');" | while read -r db; do
  if [[ -n "$db" ]]; then
    echo "   → Dropping database: $db"
    PGPASSWORD="$PASSWORD" psql -U "$USER" -h "$HOST" -p "$PORT" -d postgres -c "DROP DATABASE IF EXISTS \"$db\" WITH (FORCE);"
  fi
done

echo "✅ All user databases dropped."

# -----------------------------------------------------------------------------
# Step 2. Recreate all databases and tables
# -----------------------------------------------------------------------------
echo "[*] Creating databases and tables..."

for dataset in "${DATASETS[@]}"; do
  DB_NAME=$(echo "$dataset" | tr '[:upper:]' '[:lower:]')
  echo "-----------------------------------------------"
  echo "⚙️  Creating database and tables for: $DB_NAME"
  echo "-----------------------------------------------"

  # Create database
  PGPASSWORD="$PASSWORD" psql -U "$USER" -h "$HOST" -p "$PORT" -d postgres -c "CREATE DATABASE \"$DB_NAME\" OWNER $USER;"

  # Create tables
  PGPASSWORD="$PASSWORD" psql -U "$USER" -h "$HOST" -p "$PORT" -d "$DB_NAME" -v ON_ERROR_STOP=1 <<'EOF'
CREATE TABLE event_table (
    src_node VARCHAR,
    src_index_id VARCHAR,
    operation VARCHAR,
    dst_node VARCHAR,
    dst_index_id VARCHAR,
    event_uuid VARCHAR NOT NULL,
    timestamp_rec BIGINT,
    _id SERIAL PRIMARY KEY
);
ALTER TABLE event_table OWNER TO postgres;
CREATE UNIQUE INDEX event_table__id_uindex ON event_table (_id);
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON event_table TO postgres;

CREATE TABLE file_node_table (
    node_uuid VARCHAR NOT NULL,
    hash_id VARCHAR NOT NULL,
    path VARCHAR,
    index_id BIGINT,
    PRIMARY KEY (node_uuid, hash_id)
);
ALTER TABLE file_node_table OWNER TO postgres;

CREATE TABLE netflow_node_table (
    node_uuid VARCHAR NOT NULL,
    hash_id VARCHAR NOT NULL,
    src_addr VARCHAR,
    src_port VARCHAR,
    dst_addr VARCHAR,
    dst_port VARCHAR,
    index_id BIGINT,
    PRIMARY KEY (node_uuid, hash_id)
);
ALTER TABLE netflow_node_table OWNER TO postgres;

CREATE TABLE subject_node_table (
    node_uuid VARCHAR,
    hash_id VARCHAR,
    path VARCHAR,
    cmd VARCHAR,
    index_id BIGINT,
    PRIMARY KEY (node_uuid, hash_id)
);
ALTER TABLE subject_node_table OWNER TO postgres;
EOF

  echo "✅ Database '$DB_NAME' and tables created successfully!"
done

echo "==============================================="
echo "🎉 All databases and tables recreated successfully!"
echo "==============================================="
