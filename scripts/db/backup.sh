#!/bin/bash
# PostgreSQL Backup Script for GridTokenX
# Purpose: Create compressed backups with rotation

set -e

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups/postgresql}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${POSTGRES_DB:-gridtokenx}"
DB_USER="${POSTGRES_USER:-gridtokenx_user}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-gridtokenx_password}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/gridtokenx_${TIMESTAMP}.dump"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}GridTokenX Database Backup${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}Timestamp: $(date)${NC}"
echo -e "${YELLOW}Database: $DB_NAME${NC}"
echo -e "${YELLOW}Backup file: $BACKUP_FILE${NC}"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Check if PostgreSQL is accessible
echo -e "${YELLOW}Checking database connection...${NC}"
if ! PGPASSWORD=$POSTGRES_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c '\q' 2>/dev/null; then
    echo -e "${RED}✗ Cannot connect to database${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Database connection successful${NC}"

# Create backup
echo -e "${YELLOW}Creating backup...${NC}"
if PGPASSWORD=$POSTGRES_PASSWORD pg_dump \
    -h $DB_HOST \
    -p $DB_PORT \
    -U $DB_USER \
    -d $DB_NAME \
    -F c \
    -b \
    -v \
    -f "$BACKUP_FILE" 2>&1 | grep -v "^$"; then
    echo -e "${GREEN}✓ Backup created successfully${NC}"
else
    echo -e "${RED}✗ Backup failed${NC}"
    exit 1
fi

# Verify backup file exists and has size
if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo -e "${GREEN}✓ Backup file verified (Size: $BACKUP_SIZE)${NC}"
else
    echo -e "${RED}✗ Backup file is empty or doesn't exist${NC}"
    exit 1
fi

# List backup contents (verification)
echo -e "${YELLOW}Verifying backup contents...${NC}"
TABLE_COUNT=$(PGPASSWORD=$POSTGRES_PASSWORD pg_restore -l "$BACKUP_FILE" | grep -c "TABLE DATA" || true)
echo -e "${GREEN}✓ Backup contains $TABLE_COUNT tables${NC}"

# Cleanup old backups
echo -e "${YELLOW}Cleaning up old backups (keeping last $RETENTION_DAYS days)...${NC}"
DELETED_COUNT=0
if [ -d "$BACKUP_DIR" ]; then
    while IFS= read -r old_backup; do
        if [ -f "$old_backup" ]; then
            rm "$old_backup"
            DELETED_COUNT=$((DELETED_COUNT + 1))
        fi
    done < <(find "$BACKUP_DIR" -name "gridtokenx_*.dump" -type f -mtime +$RETENTION_DAYS)
fi

if [ $DELETED_COUNT -gt 0 ]; then
    echo -e "${GREEN}✓ Deleted $DELETED_COUNT old backup(s)${NC}"
else
    echo -e "${GREEN}✓ No old backups to delete${NC}"
fi

# List current backups
echo -e "${YELLOW}Current backups:${NC}"
ls -lh "$BACKUP_DIR"/gridtokenx_*.dump 2>/dev/null | awk '{print $9, "(" $5 ")"}'

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Backup completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}Backup location: $BACKUP_FILE${NC}"
echo -e "${YELLOW}Backup size: $BACKUP_SIZE${NC}"
echo -e "${YELLOW}Tables backed up: $TABLE_COUNT${NC}"

# Optional: Send notification (uncomment if needed)
# if command -v mail &> /dev/null; then
#     echo "Backup completed: $BACKUP_FILE" | mail -s "GridTokenX Backup Success" admin@example.com
# fi

exit 0
