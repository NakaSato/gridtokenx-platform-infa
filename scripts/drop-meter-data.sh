#!/bin/bash
# Drop all meter data from GridTokenX database

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       Drop All Meter Data - GridTokenX DB        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Database connection parameters
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-gridtokenx}"
DB_USER="${DB_USER:-gridtokenx_user}"
DB_PASS="${DB_PASS:-gridtokenx_password}"

# Check if running in Docker
if docker ps | grep -q "gridtokenx-postgres"; then
    echo -e "${YELLOW}Using Docker PostgreSQL container...${NC}"
    DOCKER_DB="gridtokenx-postgres"
    
    # Get row counts before
    echo -e "\n${YELLOW}Current meter data counts:${NC}"
    docker exec $DOCKER_DB psql -U $DB_USER -d $DB_NAME -c "SELECT 'meter_readings' as table_name, COUNT(*) as row_count FROM meter_readings;" 2>/dev/null || echo "meter_readings: table not found or empty"
    
    # Truncate meter_readings table
    echo -e "\n${YELLOW}Truncating meter_readings table...${NC}"
    docker exec $DOCKER_DB psql -U $DB_USER -d $DB_NAME -c "TRUNCATE TABLE meter_readings CASCADE;"
    
    # Check for partitioned tables
    echo -e "${YELLOW}Checking for partitioned meter_readings tables...${NC}"
    PARTITIONS=$(docker exec $DOCKER_DB psql -U $DB_USER -d $DB_NAME -t -c "
        SELECT tablename FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename LIKE 'meter_readings_%';
    " 2>/dev/null || echo "")
    
    if [ -n "$PARTITIONS" ]; then
        for partition in $PARTITIONS; do
            echo -e "  Truncating partition: ${CYAN}$partition${NC}"
            docker exec $DOCKER_DB psql -U $DB_USER -d $DB_NAME -c "TRUNCATE TABLE $partition CASCADE;" 2>/dev/null || true
        done
    fi
    
    # Check for meter_readings_archive
    echo -e "${YELLOW}Checking for meter_readings_archive table...${NC}"
    docker exec $DOCKER_DB psql -U $DB_USER -d $DB_NAME -c "TRUNCATE TABLE meter_readings_archive CASCADE;" 2>/dev/null && echo -e "  ${GREEN}✓${NC} Archived data cleared" || echo -e "  ${YELLOW}⚠${NC} No archive table found"
    
    # Reset meter statistics if table exists
    echo -e "${YELLOW}Checking for meter_statistics table...${NC}"
    docker exec $DOCKER_DB psql -U $DB_USER -d $DB_NAME -c "TRUNCATE TABLE meter_statistics CASCADE;" 2>/dev/null && echo -e "  ${GREEN}✓${NC} Statistics cleared" || echo -e "  ${YELLOW}⚠${NC} No statistics table found"
    
    # Reset any meter-related cache or materialized views
    echo -e "${YELLOW}Refreshing materialized views...${NC}"
    docker exec $DOCKER_DB psql -U $DB_USER -d $DB_NAME -c "
        DO \$\$
        DECLARE
            r RECORD;
        BEGIN
            FOR r IN SELECT matviewname FROM pg_matviews WHERE schemaname = 'public' AND matviewname LIKE '%meter%'
            LOOP
                EXECUTE 'REFRESH MATERIALIZED VIEW ' || r.matviewname;
                RAISE NOTICE 'Refreshed %', r.matviewname;
            END LOOP;
        END \$\$;
    " 2>/dev/null || echo -e "  ${YELLOW}⚠${NC} No meter materialized views found"
    
    # Clear location coordinates from meters tables
    echo -e "${YELLOW}Clearing location coordinates from meters...${NC}"
    docker exec $DOCKER_DB psql -U $DB_USER -d $DB_NAME -c "UPDATE meters SET latitude = NULL, longitude = NULL, zone_id = NULL WHERE latitude IS NOT NULL OR longitude IS NOT NULL OR zone_id IS NOT NULL;" 2>/dev/null && echo -e "  ${GREEN}✓${NC} meters coordinates cleared" || echo -e "  ${YELLOW}⚠${NC} meters table not found or no coordinates to clear"
    
    docker exec $DOCKER_DB psql -U $DB_USER -d $DB_NAME -c "UPDATE meter_registry SET latitude = NULL, longitude = NULL, zone_id = NULL WHERE latitude IS NOT NULL OR longitude IS NOT NULL OR zone_id IS NOT NULL;" 2>/dev/null && echo -e "  ${GREEN}✓${NC} meter_registry coordinates cleared" || echo -e "  ${YELLOW}⚠${NC} meter_registry table not found or no coordinates to clear"
    
    # Delete test/simulator meters
    echo -e "${YELLOW}Deleting test and simulator meters...${NC}"
    docker exec $DOCKER_DB psql -U $DB_USER -d $DB_NAME -c "DELETE FROM meters WHERE serial_number LIKE 'METER-BASH-%' OR user_id IN (SELECT id FROM users WHERE email LIKE 'simulator_%@gridtokenx.local') OR serial_number ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';" 2>/dev/null && echo -e "  ${GREEN}✓${NC} test meters deleted from meters" || echo -e "  ${YELLOW}⚠${NC} no test meters found in meters"
    docker exec $DOCKER_DB psql -U $DB_USER -d $DB_NAME -c "DELETE FROM meter_registry WHERE serial_number LIKE 'METER-BASH-%' OR user_id IN (SELECT id FROM users WHERE email LIKE 'simulator_%@gridtokenx.local') OR serial_number ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';" 2>/dev/null && echo -e "  ${GREEN}✓${NC} test meters deleted from meter_registry" || echo -e "  ${YELLOW}⚠${NC} no test meters found in meter_registry"
    
    # Verify truncation
    echo -e "\n${YELLOW}Verifying data removal...${NC}"
    COUNT=$(docker exec $DOCKER_DB psql -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM meter_readings;" 2>/dev/null | xargs)
    if [ "$COUNT" = "0" ] || [ -z "$COUNT" ]; then
        echo -e "${GREEN}✅ All meter data successfully dropped!${NC}"
    else
        echo -e "${RED}❌ Warning: $COUNT rows still remain in meter_readings${NC}"
    fi
    
else
    echo -e "${YELLOW}Using direct PostgreSQL connection...${NC}"
    
    # Check connection
    if ! PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "${RED}❌ Cannot connect to database at $DB_HOST:$DB_PORT${NC}"
        echo -e "${YELLOW}Please ensure PostgreSQL is running or Docker container 'gridtokenx-postgres' exists.${NC}"
        exit 1
    fi
    
    # Get row counts before
    echo -e "\n${YELLOW}Current meter data counts:${NC}"
    PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
        SELECT 'meter_readings' as table_name, COUNT(*) as row_count FROM meter_readings;
    " 2>/dev/null || echo "meter_readings: table not found or empty"
    
    # Truncate meter_readings table
    echo -e "\n${YELLOW}Truncating meter_readings table...${NC}"
    PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "TRUNCATE TABLE meter_readings CASCADE;"
    
    # Check for partitioned tables
    echo -e "${YELLOW}Checking for partitioned meter_readings tables...${NC}"
    PARTITIONS=$(PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "
        SELECT tablename FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename LIKE 'meter_readings_%';
    " 2>/dev/null || echo "")
    
    if [ -n "$PARTITIONS" ]; then
        for partition in $PARTITIONS; do
            echo -e "  Truncating partition: ${CYAN}$partition${NC}"
            PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "TRUNCATE TABLE $partition CASCADE;" 2>/dev/null || true
        done
    fi
    
    # Check for meter_readings_archive
    echo -e "${YELLOW}Checking for meter_readings_archive table...${NC}"
    PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "TRUNCATE TABLE meter_readings_archive CASCADE;" 2>/dev/null && echo -e "  ${GREEN}✓${NC} Archived data cleared" || echo -e "  ${YELLOW}⚠${NC} No archive table found"
    
    # Reset meter statistics if table exists
    echo -e "${YELLOW}Checking for meter_statistics table...${NC}"
    PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "TRUNCATE TABLE meter_statistics CASCADE;" 2>/dev/null && echo -e "  ${GREEN}✓${NC} Statistics cleared" || echo -e "  ${YELLOW}⚠${NC} No statistics table found"
    
    # Clear location coordinates from meters tables
    echo -e "${YELLOW}Clearing location coordinates from meters...${NC}"
    PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "UPDATE meters SET latitude = NULL, longitude = NULL, zone_id = NULL WHERE latitude IS NOT NULL OR longitude IS NOT NULL OR zone_id IS NOT NULL;" 2>/dev/null && echo -e "  ${GREEN}✓${NC} meters coordinates cleared" || echo -e "  ${YELLOW}⚠${NC} meters table not found or no coordinates to clear"
    
    PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "UPDATE meter_registry SET latitude = NULL, longitude = NULL, zone_id = NULL WHERE latitude IS NOT NULL OR longitude IS NOT NULL OR zone_id IS NOT NULL;" 2>/dev/null && echo -e "  ${GREEN}✓${NC} meter_registry coordinates cleared" || echo -e "  ${YELLOW}⚠${NC} meter_registry table not found or no coordinates to clear"
    
    # Delete test/simulator meters
    echo -e "${YELLOW}Deleting test and simulator meters...${NC}"
    PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "DELETE FROM meters WHERE serial_number LIKE 'METER-BASH-%' OR user_id IN (SELECT id FROM users WHERE email LIKE 'simulator_%@gridtokenx.local') OR serial_number ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';" 2>/dev/null && echo -e "  ${GREEN}✓${NC} test meters deleted from meters" || echo -e "  ${YELLOW}⚠${NC} no test meters found in meters"
    PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "DELETE FROM meter_registry WHERE serial_number LIKE 'METER-BASH-%' OR user_id IN (SELECT id FROM users WHERE email LIKE 'simulator_%@gridtokenx.local') OR serial_number ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';" 2>/dev/null && echo -e "  ${GREEN}✓${NC} test meters deleted from meter_registry" || echo -e "  ${YELLOW}⚠${NC} no test meters found in meter_registry"
    
    # Verify truncation
    echo -e "\n${YELLOW}Verifying data removal...${NC}"
    COUNT=$(PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM meter_readings;" 2>/dev/null | xargs)
    if [ "$COUNT" = "0" ] || [ -z "$COUNT" ]; then
        echo -e "${GREEN}✅ All meter data successfully dropped!${NC}"
    else
        echo -e "${RED}❌ Warning: $COUNT rows still remain in meter_readings${NC}"
    fi
fi

echo ""
echo -e "${CYAN}Tables/fields affected:${NC}"
echo -e "  • meter_readings (truncated)"
echo -e "  • meter_readings_* (partitions truncated)"
echo -e "  • meter_readings_archive (truncated if exists)"
echo -e "  • meter_statistics (truncated if exists)"
echo -e "  • meters.latitude (cleared)"
echo -e "  • meters.longitude (cleared)"
echo -e "  • meters.zone_id (cleared)"
echo -e "  • meter_registry.latitude (cleared)"
echo -e "  • meter_registry.longitude (cleared)"
echo -e "  • meter_registry.zone_id (cleared)"
echo ""
