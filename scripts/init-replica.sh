#!/bin/bash
set -e

# If the data directory is empty, perform a base backup from the primary
if [ -z "$(ls -A "$PGDATA")" ]; then
    echo "Data directory is empty, performing base backup from $PRIMARY_HOST..."
    until pg_basebackup -h "$PRIMARY_HOST" -D "$PGDATA" -U replication -Fp -Xs -P -R; do
        echo "Primary is not ready, retrying in 2 seconds..."
        sleep 2
    done
    echo "Base backup complete."
fi

# Start PostgreSQL normally
exec postgres
