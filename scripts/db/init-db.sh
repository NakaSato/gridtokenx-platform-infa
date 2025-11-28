#!/bin/bash
# Database Initialization Script
# Purpose: Initialize PostgreSQL database with extensions and monitoring

set -e

# Configuration
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${POSTGRES_DB:-gridtokenx}"
DB_USER="${POSTGRES_USER:-gridtokenx_user}"
DB_PASSWORD="${POSTGRES_PASSWORD:-gridtokenx_password}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}GridTokenX Database Initialization${NC}"
echo -e "${GREEN}========================================${NC}"

# Function to run SQL command
run_sql() {
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "$1"
}

# Function to run SQL file
run_sql_file() {
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$1"
}

# Wait for PostgreSQL to be ready
echo -e "${YELLOW}Waiting for PostgreSQL to be ready...${NC}"
until PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c '\q' 2>/dev/null; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 2
done
echo -e "${GREEN}✓ PostgreSQL is ready${NC}"

# Create database if it doesn't exist
echo -e "${YELLOW}Checking database existence...${NC}"
if ! PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
    echo -e "${YELLOW}Creating database $DB_NAME...${NC}"
    PGPASSWORD=$DB_PASSWORD createdb -h $DB_HOST -p $DB_PORT -U $DB_USER $DB_NAME
    echo -e "${GREEN}✓ Database created${NC}"
else
    echo -e "${GREEN}✓ Database already exists${NC}"
fi

# Enable required extensions
echo -e "${YELLOW}Enabling PostgreSQL extensions...${NC}"
run_sql "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";" && echo -e "${GREEN}✓ uuid-ossp enabled${NC}"
run_sql "CREATE EXTENSION IF NOT EXISTS \"pgcrypto\";" && echo -e "${GREEN}✓ pgcrypto enabled${NC}"
run_sql "CREATE EXTENSION IF NOT EXISTS \"pg_stat_statements\";" && echo -e "${GREEN}✓ pg_stat_statements enabled${NC}"

# Run migrations
echo -e "${YELLOW}Running database migrations...${NC}"
if [ -d "gridtokenx-apigateway/migrations" ]; then
    cd gridtokenx-apigateway
    
    # Check if sqlx is available
    if command -v sqlx &> /dev/null; then
        echo -e "${YELLOW}Running migrations with sqlx...${NC}"
        DATABASE_URL="postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME" sqlx migrate run
        echo -e "${GREEN}✓ Migrations completed${NC}"
    else
        echo -e "${YELLOW}sqlx not found, running migrations manually...${NC}"
        for migration in migrations/*.sql; do
            if [ -f "$migration" ]; then
                echo "Running $migration..."
                run_sql_file "$migration"
            fi
        done
        echo -e "${GREEN}✓ Migrations completed${NC}"
    fi
    cd ..
else
    echo -e "${RED}✗ Migrations directory not found${NC}"
fi

# Create monitoring views
echo -e "${YELLOW}Creating monitoring views...${NC}"
if [ -f "scripts/db/monitoring-queries.sql" ]; then
    run_sql_file "scripts/db/monitoring-queries.sql"
    echo -e "${GREEN}✓ Monitoring views created${NC}"
fi

# Display database info
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Database Information${NC}"
echo -e "${GREEN}========================================${NC}"
run_sql "SELECT version();" | head -3
echo ""
run_sql "SELECT current_database(), current_user;"
echo ""

# Display table count
echo -e "${YELLOW}Tables in database:${NC}"
run_sql "SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = 'public';"

# Display extension list
echo -e "${YELLOW}Installed extensions:${NC}"
run_sql "SELECT extname, extversion FROM pg_extension WHERE extname NOT IN ('plpgsql');"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Database initialization complete!${NC}"
echo -e "${GREEN}========================================${NC}"
