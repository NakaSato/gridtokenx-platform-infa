#!/bin/bash
set -e

echo "🚀 Starting GridTokenX Local Load Test Environment"
echo "   (Infrastructure via Docker, Apps Native)"
echo "-----------------------------------------------"

# 1. Start Infrastructure only
echo "📦 Starting Infrastructure (Postgres, Redis, Kafka, InfluxDB)..."
docker-compose up -d postgres redis kafka influxdb mailpit
echo "✅ Infrastructure running."

# 2. Wait for Postgres
echo "⏳ Waiting for Database..."
sleep 5

# 3. Start API Gateway (Native)
echo "🦀 Starting API Gateway (Native)..."
export DATABASE_URL=postgresql://gridtokenx_user:gridtokenx_password@localhost:5432/gridtokenx
export REDIS_URL=redis://localhost:6379
export KAFKA_BOOTSTRAP_SERVERS=localhost:9092
export INFLUXDB_URL=http://localhost:8086
export SIMULATOR_URL=http://localhost:8080
export SOLANA_RPC_URL=http://localhost:8899
export RUST_LOG=info

# Build first to see errors clearly
cd gridtokenx-apigateway
cargo build --bin api-gateway
nohup cargo run --bin api-gateway > ../api_gateway_local.log 2>&1 &
API_PID=$!
echo "✅ API Gateway started with PID $API_PID. Logs: api_gateway_local.log"
cd ../scripts

# 4. Run Load Test
echo "⚡ Executing Load Test Script..."
# Create a modified run_load_test to NOT reset DB if needed? 
# The run_load_test.sh script resets DB via docker exec psql, which is compatible.
./run_load_test.sh

echo "-----------------------------------------------"
echo "Test Environment Running:"
echo "   API Gateway PID: $API_PID"
echo "   Infrastructure: Docker"
echo "   Simulator: Native (Background)"
echo ""
echo "Monitor Logs:"
echo "   tail -f ../api_gateway_local.log"
echo "   tail -f ../gridtokenx-smartmeter-simulator/simulator_loadtest.log"
echo ""
echo "To Stop:"
echo "   kill $API_PID"
echo "   docker-compose down"
