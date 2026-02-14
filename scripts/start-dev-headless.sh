#!/bin/bash
# GridTokenX Development Environment Setup Script (Headless)
set -m # Enable job control

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_ROOT="/Users/chanthawat/Developments/gridtokenx-platform-infa"
ANCHOR_DIR="$PROJECT_ROOT/gridtokenx-anchor"
GATEWAY_DIR="$PROJECT_ROOT/gridtokenx-apigateway"
DEV_WALLET="$GATEWAY_DIR/dev-wallet.json"
LOG_DIR="$PROJECT_ROOT/scripts/logs"

RPC_URL="http://localhost:8899"
WS_URL="ws://localhost:8900"

mkdir -p "$LOG_DIR"

cleanup() {
    echo -e "${YELLOW}🧹 Stopping all background processes...${NC}"
    kill $(jobs -p) 2>/dev/null
    exit
}
trap cleanup SIGINT SIGTERM

echo -e "${BLUE}=== GridTokenX Headless Startup ===${NC}"

# Helper functions
wait_for_validator() {
    echo -e "${YELLOW}⏳ Waiting for validator...${NC}"
    for i in {1..30}; do
        if solana cluster-version --url $RPC_URL &>/dev/null; then
            echo -e "${GREEN}✅ Validator ready!${NC}"
            return 0
        fi
        sleep 1
    done
    return 1
}

update_env_file() {
    local file=$1
    local var=$2
    local value=$3
    if [ -f "$file" ]; then
        if grep -q "^${var}=" "$file"; then
            sed -i '' "s|^${var}=.*|${var}=${value}|" "$file"
        else
            echo "${var}=${value}" >> "$file"
        fi
    fi
}

# 1. Cleanup
pkill -f "solana-test-validator" 2>/dev/null || true
pkill -f "api-gateway" 2>/dev/null || true
pkill -f "uvicorn" 2>/dev/null || true
pkill -f "next-server" 2>/dev/null || true

# 2. Docker
echo -e "${YELLOW}🐳 Checking Docker...${NC}"
DOCKER_AVAILABLE=true
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}⚠️ Docker not running. Switching to LITE MODE (Blockchain + Frontend Only).${NC}"
    echo -e "${RED}   - Postgres, Redis, API Gateway, and Simulator API will be SKIPPED.${NC}"
    DOCKER_AVAILABLE=false
else
    echo -e "${YELLOW}🐳 Starting Docker services...${NC}"
    docker-compose up -d postgres redis mailpit kafka influxdb
fi

# 3. Validator
echo -e "${YELLOW}🔗 Starting Validator...${NC}"
solana-test-validator --reset > "$LOG_DIR/validator.log" 2>&1 &
wait_for_validator

# 4. Config & Funding
solana config set --url $RPC_URL

DEPLOYER="3WZvSfxowwY2MvM4fwjTbTUSvjA4TNAr2M4rqv4Ejm31"
ANCHOR_WALLET="AfPVU1umftejsJaVaZA5RMLqX9RfkZQN23oD8LLJTWUS"

echo "💰 Funding Wallets..."
# Airdrop loop - try multiple times to ensure funding
for i in {1..5}; do
    echo "  - Airdrop attempt $i..."
    solana airdrop 100 $DEV_PUBKEY --url $RPC_URL >/dev/null 2>&1 || true
    solana airdrop 100 $DEPLOYER --url $RPC_URL >/dev/null 2>&1 || true
    solana airdrop 100 $ANCHOR_WALLET --url $RPC_URL >/dev/null 2>&1 || true
    sleep 2
done

# Verification loop
echo "⏳ Verifying Balances..."
for i in {1..30}; do
    BAL_DEV=$(solana balance $DEV_PUBKEY --url $RPC_URL | awk '{print $1}')
    BAL_DEP=$(solana balance $DEPLOYER --url $RPC_URL | awk '{print $1}')
    BAL_ANC=$(solana balance $ANCHOR_WALLET --url $RPC_URL | awk '{print $1}')
    
    # Check if they are numbers and have sufficient funds
    if [[ "$BAL_DEV" =~ ^[0-9]+(\.[0-9]+)?$ ]] && (( $(echo "$BAL_DEV > 10" | bc -l) )) && \
       [[ "$BAL_DEP" =~ ^[0-9]+(\.[0-9]+)?$ ]] && (( $(echo "$BAL_DEP > 50" | bc -l) )) && \
       [[ "$BAL_ANC" =~ ^[0-9]+(\.[0-9]+)?$ ]] && (( $(echo "$BAL_ANC > 10" | bc -l) )); then
        echo "✅ Balances confirmed: Dev=$BAL_DEV, Deployer=$BAL_DEP, Anchor=$BAL_ANC"
        break
    fi
    sleep 1
done

# 5. Init Blockchain
echo -e "${YELLOW}📜 Initializing Blockchain...${NC}"
yes | bash "$PROJECT_ROOT/scripts/init_blockchain.sh" > "$LOG_DIR/init_blockchain.log" 2>&1

# 6. Create Token
echo -e "${YELLOW}🪙 Creating Energy Token...${NC}"
cd "$GATEWAY_DIR"
TOKEN_OUTPUT=$(spl-token create-token \
    --program-id TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb \
    --enable-permanent-delegate \
    --decimals 9 \
    --fee-payer "$DEV_WALLET" \
    --mint-authority "$DEV_WALLET" \
    --url $RPC_URL 2>&1)
ENERGY_TOKEN_MINT=$(echo "$TOKEN_OUTPUT" | grep "Address:" | awk '{print $2}')
echo "Mint: $ENERGY_TOKEN_MINT"

# 7. Update Envs
update_env_file "$GATEWAY_DIR/.env" "ENERGY_TOKEN_MINT" "$ENERGY_TOKEN_MINT"
update_env_file "$GATEWAY_DIR/.env" "SOLANA_RPC_URL" "$RPC_URL"
update_env_file "$PROJECT_ROOT/.env" "ENERGY_TOKEN_MINT" "$ENERGY_TOKEN_MINT"
update_env_file "$PROJECT_ROOT/.env" "SOLANA_RPC_URL" "$RPC_URL"
update_env_file "$GATEWAY_DIR/.env" "KAFKA_BOOTSTRAP_SERVERS" "localhost:9092"
TRADING_ENV="$PROJECT_ROOT/gridtokenx-trading/.env"
if [ -f "$TRADING_ENV" ]; then
    update_env_file "$TRADING_ENV" "NEXT_PUBLIC_ENERGY_TOKEN_MINT" "$ENERGY_TOKEN_MINT"
fi

# 8. Start Services
echo -e "${YELLOW}🚀 Launching Services in Background...${NC}"

if [ "$DOCKER_AVAILABLE" = true ]; then
    # API Gateway
    echo "  Starting API Gateway..."
    cd "$GATEWAY_DIR"
    export KAFKA_BOOTSTRAP_SERVERS=localhost:9092
    cargo run --bin api-gateway > "$LOG_DIR/api_gateway.log" 2>&1 &

    # Simulator API
    echo "  Starting Simulator API..."
    cd "$PROJECT_ROOT/gridtokenx-smartmeter-simulator"
    # Assuming venv exists or using specific python
    (source .venv/bin/activate && export PYTHONPATH=$PYTHONPATH:. && python -m uvicorn src.app.main:app --reload --host 0.0.0.0 --port 8000) > "$LOG_DIR/simulator_api.log" 2>&1 &
else 
    echo -e "${RED}  - Skipping API Gateway (No DB)${NC}"
    echo -e "${RED}  - Skipping Simulator API (No DB)${NC}"
fi

# Simulator UI
echo "  Starting Simulator UI..."
cd "$PROJECT_ROOT/gridtokenx-smartmeter-simulator"
bun run dev > "$LOG_DIR/simulator_ui.log" 2>&1 &

# Trading UI
echo "  Starting Trading UI..."
cd "$PROJECT_ROOT/gridtokenx-trading"
bun run dev > "$LOG_DIR/trading_ui.log" 2>&1 &

# Admin UI
echo "  Starting Admin UI..."
cd "$PROJECT_ROOT/gridtokenx-admin"
bun run dev > "$LOG_DIR/admin_ui.log" 2>&1 &

echo -e "${GREEN}✅ All systems go! Logs in $LOG_DIR${NC}"
echo -e "${YELLOW}Hit Ctrl+C to stop all services.${NC}"

# Keep alive
wait
