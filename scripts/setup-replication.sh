#!/bin/bash
set -e

# Create a replication user if it doesn't exist
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER replication WITH REPLICATION PASSWORD '$POSTGRES_PASSWORD';
EOSQL

# Add replication entry to pg_hba.conf
echo "host replication replication 0.0.0.0/0 md5" >> "$PGDATA/pg_hba.conf"
