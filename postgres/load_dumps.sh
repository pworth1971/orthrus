#!/bin/bash

#!/bin/bash
for dump_file in ../data/*.dump; do
  db_name=$(basename "$dump_file" .dump)
  echo "Recreating database '$db_name' and restoring from $dump_file..."

  # Drop and recreate database to ensure a clean restore
  psql -U postgres -h localhost -p 5432 -c "DROP DATABASE IF EXISTS \"$db_name\";"
  psql -U postgres -h localhost -p 5432 -c "CREATE DATABASE \"$db_name\";"

  # Restore dump
  pg_restore -U postgres -h localhost -p 5432 -d "$db_name" "$dump_file"
done


for dump_file in ./data/*.dump; do
  db_name=$(basename "$dump_file" .dump)

  echo "Restoring $dump_file into database '$db_name'..."

  pg_restore -U postgres -h localhost -p 5432 -d "$db_name" "$dump_file"
done
