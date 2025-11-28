#!/bin/bash
# PostgreSQL Restore Script for GridTokenX
# Purpose: Restore database from backup

set -e

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups/postgresql}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${POSTGRES_DB:-gridtokenx}"
DB_USER="${POSTGRES_USER:-gridtokenx_user}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-gridtokenx_password}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}GridTokenX Database Restore${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${RED}✗ Backup directory not found: $BACKUP_DIR${NC}"
    exit 1
fi

# List available backups
echo -e "${YELLOW}Available backups:${NC}"
BACKUPS=($(ls -t "$BACKUP_DIR"/gridtokenx_*.dump 2>/dev/null))

if [ ${#BACKUPS[@]} -eq 0 ]; then
    echo -e "${RED}✗ No backups found in $BACKUP_DIR${NC}"
    exit 1
fi

# Display backups with numbers
for i in "${!BACKUPS[@]}"; do
    BACKUP_SIZE=$(du -h "${BACKUPS[$i]}" | cut -f1)
    BACKUP_DATE=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "${BACKUPS[$i]}" 2>/dev/null || stat -c "%y" "${BACKUPS[$i]}" 2>/dev/null | cut -d'.' -f1)
    echo "$((i+1)). $(basename ${BACKUPS[$i]}) - $BACKUP_SIZE - $BACKUP_DATE"
done

# Get user selection
if [ -z "$1" ]; then
    echo ""
    read -p "Select backup number to restore (1-${#BACKUPS[@]}): " SELECTION
else
    SELECTION=$1
fi

# Validate selection
if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt "${#BACKUPS[@]}" ]; then
    echo -e "${RED}✗ Invalid selection${NC}"
    exit 1
fi

BACKUP_FILE="${BACKUPS[$((SELECTION-1))]}"
echo -e "${YELLOW}Selected backup: $(basename $BACKUP_FILE)${NC}"

# Confirm restore
echo ""
echo -e "${RED}WARNING: This will drop and recreate the database!${NC}"
echo -e "${RED}All current data will be lost!${NC}"
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Restore cancelled${NC}"
    exit 0
fi

# Check database connection
echo -e "${YELLOW}Checking database connection...${NC}"
if ! PGPASSWORD=$POSTGRES_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c '\q' 2>/dev/null; then
    echo -e "${RED}✗ Cannot connect to PostgreSQL server${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Database connection successful${NC}"

# Terminate existing connections
echo -e "${YELLOW}Terminating existing connections...${NC}"
PGPASSWORD=$POSTGRES_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '$DB_NAME'
AND pid <> pg_backend_pid();
" 2>/dev/null || true
echo -e "${GREEN}✓ Connections terminated${NC}"

# Drop existing database
echo -e "${YELLOW}Dropping existing database...${NC}"
PGPASSWORD=$POSTGRES_PASSWORD dropdb -h $DB_HOST -p $DB_PORT -U $DB_USER --if-exists $DB_NAME
echo -e "${GREEN}✓ Database dropped${NC}"

# Create new database
echo -e "${YELLOW}Creating new database...${NC}"
PGPASSWORD=$POSTGRES_PASSWORD createdb -h $DB_HOST -p $DB_PORT -U $DB_USER $DB_NAME
echo -e "${GREEN}✓ Database created${NC}"

# Restore from backup
echo -e "${YELLOW}Restoring from backup...${NC}"
if PGPASSWORD=$POSTGRES_PASSWORD pg_restore \
    -h $DB_HOST \
    -p $DB_PORT \
    -U $DB_USER \
    -d $DB_NAME \
    -v \
    -j 4 \
    "$BACKUP_FILE" 2>&1 | grep -v "^$"; then
    echo -e "${GREEN}✓ Restore completed${NC}"
else
    # pg_restore may return non-zero even on success due to warnings
    echo -e "${YELLOW}⚠ Restore completed with warnings (this is usually normal)${NC}"
fi

# Verify restore
echo -e "${YELLOW}Verifying restore...${NC}"
TABLE_COUNT=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "
SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';
" | tr -d ' ')

if [ "$TABLE_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ Restore verified ($TABLE_COUNT tables restored)${NC}"
else
    echo -e "${RED}✗ Restore verification failed (no tables found)${NC}"
    exit 1
fi

# Run ANALYZE to update statistics
echo -e "${YELLOW}Updating database statistics...${NC}"
PGPASSWORD=$POSTGRES_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "ANALYZE;" >/dev/null
echo -e "${GREEN}✓ Statistics updated${NC}"

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Restore completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}Restored from: $(basename $BACKUP_FILE)${NC}"
echo -e "${YELLOW}Tables restored: $TABLE_COUNT${NC}"
echo -e "${YELLOW}Database: $DB_NAME${NC}"

exit 0
