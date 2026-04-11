#!/bin/bash
# GridTokenX - 20,000 Meter Stress Test Script
#
# This script launches the smart-meter-simulator in standalone mode
# to stress test the ingestion pipeline of the GridTokenX platform.

set -e

# Configuration
NUM_METERS=20000
SIMULATION_INTERVAL=60
TRANSPORT_TYPE="grpc"
GRPC_HOST="127.0.0.1"
GRPC_PORT=4015
API_URL="http://127.0.0.1:4000"
API_KEY="engineering-department-api-key-2025"

# Environment Paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIMULATOR_DIR="$PROJECT_ROOT/gridtokenx-smartmeter-simulator"
BIN_PATH="/Users/chanthawat/.local/bin:/usr/local/bin:$PATH"

echo "========================================================================"
echo "    GridTokenX - 20,000 Meter Stress Test Initiator"
echo "========================================================================"
echo "📊 Scale: $NUM_METERS meters"
echo "⏱️  Interval: $SIMULATION_INTERVAL seconds"
echo "🌐 Transport: $TRANSPORT_TYPE ($GRPC_HOST:$GRPC_PORT)"
echo "🚀 Mode: Standalone (High-Performance)"
echo "========================================================================"

# Check if UV is available
export PATH="$BIN_PATH"
if ! command -v uv &> /dev/null; then
    echo "[ERROR] 'uv' not found. Please ensure it is in your PATH."
    exit 1
fi

# Navigate to simulator directory
cd "$SIMULATOR_DIR"

# Launch Simulator
echo "[INFO] Launching simulator..."
export GRPC_GATEWAY_HOST=$GRPC_HOST
export GRPC_GATEWAY_PORT=$GRPC_PORT
uv run start-simulator \
    --mode standalone \
    --meters $NUM_METERS \
    --interval $SIMULATION_INTERVAL \
    --api-url $API_URL \
    --api-key $API_KEY \
    --transport $TRANSPORT_TYPE \
    --fast-ingestion

echo "========================================================================"
echo "    Stress Test Terminated"
echo "========================================================================"
