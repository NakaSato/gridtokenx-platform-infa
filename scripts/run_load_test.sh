#!/bin/bash
set -e

# Configuration
SIMULATOR_DIR="../gridtokenx-smartmeter-simulator"
PROJECT_ROOT=".."
DOCKER_CONTAINER="gridtokenx-postgres"
DB_USER="gridtokenx_user"
DB_NAME="gridtokenx"
VENV_ACTIVATE="$SIMULATOR_DIR/.venv/bin/activate"

echo "🚀 Starting GridTokenX Load Test (1000 Meters)"
echo "-----------------------------------------------"

# 1. Generate Data
echo "📦 Generating datasets..."
python3 generate_load_test_data.py

# 2. Seed API Gateway Database
echo "floppy_disk: Seeding API Gateway Database..."
if docker exec -i $DOCKER_CONTAINER psql -U $DB_USER -d $DB_NAME < seed_1000_users.sql; then
    echo "✅ Database seeded successfully."
else
    echo "❌ Failed to seed database. Is Docker running?"
    exit 1
fi

# 3. Seed Simulator
echo "⚡ Seeding Simulator..."
# Ensure simulator venv is active
if [ -f "$VENV_ACTIVATE" ]; then
    source "$VENV_ACTIVATE"
else
    echo "❌ Simulator .venv not found at $VENV_ACTIVATE"
    exit 1
fi

# Copy CSV to simulator dir
cp load_test_meters.csv "$SIMULATOR_DIR/"

# Run simulator seed script
cd "$SIMULATOR_DIR"
python3 seed_mea_data.py load_test_meters.csv

# 4. Start Simulator
echo "▶️  Starting Simulator (Background)..."
# Check if already running
if [ -f "simulator.pid" ]; then
    PID=$(cat simulator.pid)
    if ps -p $PID > /dev/null; then
        echo "⚠️  Simulator already running (PID $PID). Killing..."
        kill $PID || true
    fi
fi

# Run simulator
nohup python3 -m uvicorn src.app.main:app --host 0.0.0.0 --port 8080 > simulator_loadtest.log 2>&1 &
SIM_PID=$!
echo $SIM_PID > simulator.pid
echo "✅ Simulator started with PID $SIM_PID. Logs: simulator_loadtest.log"

echo "-----------------------------------------------"
echo "Load test environment is running!"
echo "Monitor API Gateway logs to verify data ingestion."
echo "To stop simulator: kill \$(cat simulator.pid)"
