#!/bin/bash

# GridTokenX E2E Telemetry Security Test Runner
# Verifies the secure ingestion link between Gateway and Oracle Bridge.

set -e

echo "🚀 Starting E2E Secure Telemetry Verification..."

# 1. Ensure directories exist
mkdir -p tests/e2e/proto

# 2. Compile Protos (using uv for dependencies)
echo "[*] Compiling Protos..."
cd gridtokenx-smartmeter-simulator
uv run python -m grpc_tools.protoc \
    -I ../gridtokenx-oracle-bridge/proto \
    --python_out=../tests/e2e/proto \
    --grpc_python_out=../tests/e2e/proto \
    oracle.proto
cd ..

# 3. Ensure register script is executable
chmod +x scripts/register-edge-key.sh

# 4. Run the Python Test Suite
echo "[*] Launching Test Suite..."
uv run --project gridtokenx-smartmeter-simulator python tests/e2e/test_telemetry_security.py

echo "✅ E2E Test Sequence Completed."
