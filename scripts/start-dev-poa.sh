#!/bin/bash
# GridTokenX Development Environment with PoA Cluster
set -m # Enable job control

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="/Users/chanthawat/Developments/gridtokenx-platform-infa"
ANCHOR_DIR="$PROJECT_ROOT/gridtokenx-anchor"
GATEWAY_DIR="$PROJECT_ROOT/gridtokenx-apigateway"
LOG_DIR="$PROJECT_ROOT/scripts/logs"
POA_SCRIPT="$ANCHOR_DIR/scripts/poa-cluster/start-cluster.sh"

export SOLANA_RPC_URL="http://localhost:8899"
export SOLANA_WS_URL="ws://localhost:8900"
export KAFKA_BOOTSTRAP_SERVERS="localhost:29092"

mkdir -p "$LOG_DIR"

cleanup() {
    echo -e "${YELLOW}🧹 Stopping all background processes...${NC}"
    kill $(jobs -p) 2>/dev/null
    pkill -f solana-validator
    pkill -f api-gateway
    docker-compose down
    exit
}
trap cleanup SIGINT SIGTERM

echo -e "${BLUE}=== GridTokenX PoA Dev Start ===${NC}"

# 1. Cleanup
pkill -f "solana-test-validator" 2>/dev/null || true
pkill -f "api-gateway" 2>/dev/null || true

# 2. Docker
echo -e "${YELLOW}🐳 Starting Docker services...${NC}"
docker-compose up -d postgres redis mailpit kafka influxdb

# 3. Start PoA Cluster
echo -e "${YELLOW}🔗 Starting PoA Cluster...${NC}"
"$POA_SCRIPT" > "$LOG_DIR/poa_cluster.log" 2>&1 &
echo "⏳ Waiting for cluster to stabilize (20s)..."
sleep 20

if solana cluster-version --url $SOLANA_RPC_URL >/dev/null; then
    echo -e "${GREEN}✅ PoA Cluster ready!${NC}"
else
    echo -e "${RED}❌ PoA Cluster failed to start. Check logs.${NC}"
    exit 1
fi

# 4. Fund Deployer
echo "${YELLOW}💰 Funding Deployer...${NC}"
DEPLOYER=$(solana address)
# Use the faucet keypair from PoA setup to fund deployer
FAUCET_KEYPAIR="$ANCHOR_DIR/scripts/poa-cluster/genesis/faucet-keypair.json"
# Transfer 5000 SOL to deployer
solana transfer --from "$FAUCET_KEYPAIR" "$DEPLOYER" 5000 --allow-unfunded-recipient --fee-payer "$FAUCET_KEYPAIR" --url $SOLANA_RPC_URL

# 5. Init Blockchain
echo -e "${YELLOW}📜 Initializing Blockchain...${NC}"
# Use existing init script but ensure it points to local cluster
yes | bash "$PROJECT_ROOT/scripts/init_blockchain.sh" > "$LOG_DIR/init_blockchain.log" 2>&1

# 6. Start API Gateway
echo -e "${YELLOW}🚀 Starting API Gateway...${NC}"
cd "$GATEWAY_DIR"
cargo run --bin api-gateway > "$LOG_DIR/api_gateway.log" 2>&1 &

# Wait for API Gateway to be ready
echo -e "${YELLOW}⏳ Waiting for API Gateway to be ready on port 4000...${NC}"
MAX_RETRIES=30
RETRY_COUNT=0
while ! curl -s http://127.0.0.1:4000/health > /dev/null; do
    sleep 2
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo -e "${RED}❌ API Gateway failed to start within 60s${NC}"
        break
    fi
done
echo -e "${GREEN}✅ API Gateway is ready!${NC}"

# 7. Start Simulator API
echo -e "${YELLOW}📊 Starting Simulator API...${NC}"
cd "$PROJECT_ROOT/gridtokenx-smartmeter-simulator"
# Export overrides for local execution - use 127.0.0.1 to avoid IPv6 issues
export API_GATEWAY_URL="http://127.0.0.1:4000"
export KAFKA_BOOTSTRAP_SERVERS="localhost:29092"
export KAFKA_ENABLED="true"
export KAFKA_TOPIC="meter-readings"
# Use venv if available
if [ -d ".venv" ]; then
    source .venv/bin/activate
fi
export PYTHONPATH=$PYTHONPATH:.
python -m uvicorn src.app.main:app --reload --host 0.0.0.0 --port 8080 > "$LOG_DIR/simulator_api.log" 2>&1 &

# 8. Start UIs
echo -e "${YELLOW}🖥️ Starting UIs...${NC}"
cd "$PROJECT_ROOT/gridtokenx-trading" && bun run dev > "$LOG_DIR/trading_ui.log" 2>&1 &
cd "$PROJECT_ROOT/gridtokenx-admin" && bun run dev > "$LOG_DIR/admin_ui.log" 2>&1 &

echo -e "${GREEN}✅ All systems running on PoA Cluster!${NC}"
echo -e "${YELLOW}Hit Ctrl+C to stop.${NC}"
wait
