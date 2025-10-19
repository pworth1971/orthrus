#!/bin/bash
set -e  # Exit immediately on any command failure

USER="postgres"
HOST="localhost"
PORT="5432"

# List of databases to reset
DATABASES=(
  clearscope_e3
  cadets_e3
  theia_e3
  clearscope_e5
  cadets_e5
  theia_e5
  optc_051
  optc_201
  optc_501
)

echo "==============================================="
echo "🚀 Resetting all PostgreSQL databases..."
echo "==============================================="

for DB in "${DATABASES[@]}"; do
  echo ""
  echo "🔹 Processing database: $DB"

  # Drop database if it exists
  echo "   → Dropping database (if exists)..."
  psql -U "$USER" -h "$HOST" -p "$PORT" -c "DROP DATABASE IF EXISTS \"$DB\";"

  # Create a new empty database
  echo "   → Creating fresh database..."
  psql -U "$USER" -h "$HOST" -p "$PORT" -c "CREATE DATABASE \"$DB\";"

  echo "✅ Database '$DB' recreated successfully!"
done

echo ""
echo "==============================================="
echo "🎉 All databases dropped and recreated successfully!"
echo "==============================================="
