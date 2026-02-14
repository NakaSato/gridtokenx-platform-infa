#!/bin/bash
# GridTokenX Development Environment Setup Script
# This script initializes the Solana localnet, creates tokens, and starts the API Gateway
#
# Usage: ./scripts/start-dev.sh
#
# Features:
# - Starts Solana test validator
# - Funds development wallets
# - Creates SPL energy token with correct mint authority
# - Updates .env files with token configuration
# - Starts the API Gateway with proper configuration

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Project directories
PROJECT_ROOT="/Users/chanthawat/Developments/gridtokenx-platform-infa"
ANCHOR_DIR="$PROJECT_ROOT/gridtokenx-anchor"
GATEWAY_DIR="$PROJECT_ROOT/gridtokenx-apigateway"
DEV_WALLET="$GATEWAY_DIR/dev-wallet.json"

# Solana config
RPC_URL="http://localhost:8899"
WS_URL="ws://localhost:8900"

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       GridTokenX Development Environment Setup     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to wait for validator
wait_for_validator() {
    echo -e "${YELLOW}⏳ Waiting for Solana validator to be ready...${NC}"
    for i in {1..30}; do
        if solana cluster-version --url $RPC_URL &>/dev/null; then
            echo -e "${GREEN}✅ Validator is ready!${NC}"
            return 0
        fi
        sleep 1
    done
    echo -e "${RED}❌ Validator failed to start${NC}"
    return 1
}

# Function to update env files
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

# ============================================================================
# Step 1: Kill existing processes
# ============================================================================
echo -e "${YELLOW}🧹 Cleaning up existing processes...${NC}"
pkill -f "solana-test-validator" 2>/dev/null || true
pkill -f "api-gateway" 2>/dev/null || true
pkill -f "uvicorn" 2>/dev/null || true
sleep 2
echo -e "${GREEN}✅ Cleanup complete${NC}"

# ============================================================================
# Step 2: Check Docker services
# ============================================================================
echo ""
echo -e "${YELLOW}🐳 Checking Docker services...${NC}"
cd "$PROJECT_ROOT"
if ! docker ps | grep -q "gridtokenx-postgres"; then
    echo -e "${YELLOW}Starting Docker services...${NC}"
    docker-compose up -d postgres redis mailpit 2>/dev/null || docker-compose up -d postgres redis
    sleep 5
fi
echo -e "${GREEN}✅ Docker services running${NC}"

# ============================================================================
# Step 3: Start Solana test validator
# ============================================================================
echo ""
echo -e "${YELLOW}🔗 Starting Solana test validator...${NC}"

# Ensure log directory exists
mkdir -p scripts/logs

# Start validator in background with reset and log redirection
solana-test-validator --reset > scripts/logs/validator.log 2>&1 &
VALIDATOR_PID=$!
echo "Validator PID: $VALIDATOR_PID"

wait_for_validator
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to start validator. Exiting.${NC}"
    exit 1
fi

# ============================================================================
# Step 4: Configure Solana CLI
# ============================================================================
echo ""
echo -e "${YELLOW}⚙️ Configuring Solana CLI...${NC}"
solana config set --url $RPC_URL --keypair ~/.config/solana/id.json
echo -e "${GREEN}✅ CLI configured${NC}"

# ============================================================================
# Step 5: Fund wallets
# ============================================================================
echo ""
echo -e "${YELLOW}💰 Funding wallets...${NC}"

# Fund default keypair
DEFAULT_PUBKEY=$(solana address)
echo "  Default keypair: $DEFAULT_PUBKEY"
solana airdrop 100 $DEFAULT_PUBKEY --url $RPC_URL 2>/dev/null || true

# Ensure dev wallet exists in gateway directory
if [ ! -f "$DEV_WALLET" ]; then
    # Copy from project root if exists, or create new
    if [ -f "$PROJECT_ROOT/dev-wallet.json" ]; then
        cp "$PROJECT_ROOT/dev-wallet.json" "$DEV_WALLET"
    else
        echo "  Creating new dev wallet..."
        solana-keygen new --no-bip39-passphrase --outfile "$DEV_WALLET" 2>/dev/null
    fi
fi

# Fund dev wallet
DEV_PUBKEY=$(solana-keygen pubkey "$DEV_WALLET")
echo "  Dev wallet: $DEV_PUBKEY"
solana airdrop 100 $DEV_PUBKEY --url $RPC_URL 2>/dev/null || true
sleep 2

echo -e "${GREEN}✅ Wallets funded${NC}"

# ============================================================================
# Step 5b: Initialize Blockchain Programs
# ============================================================================
echo ""
echo -e "${YELLOW}📜 Initializing Blockchain Programs...${NC}"
bash "$PROJECT_ROOT/scripts/init_blockchain.sh"
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to initialize blockchain code. Exiting.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Blockchain programs deployed${NC}"


# ============================================================================
# Step 6: Initialize Blockchain Programs & Create Energy Token (Anchor Bootstrap)
# ============================================================================
echo ""
echo -e "${YELLOW}🪙 Initializing Blockchain State & PDAs...${NC}"

# Run Anchor Bootstrap script to initialize Registry, Market, and Energy Token
cd "$ANCHOR_DIR"

# Set Anchor environment variables for scripts
export ANCHOR_PROVIDER_URL="$RPC_URL"
export ANCHOR_WALLET="$DEV_WALLET"

pnpm ts-node scripts/bootstrap.ts

# Get PDA addresses using get_pdas.ts
echo -e "${YELLOW}🔍 Extracting PDA configuration...${NC}"
PDA_CONFIG=$(pnpm ts-node scripts/get_pdas.ts)

# Extract addresses using grep and awk
ENERGY_TOKEN_MINT=$(echo "$PDA_CONFIG" | grep "ENERGY_TOKEN_MINT=" | cut -d'=' -f2)
REGISTRY_PDA=$(echo "$PDA_CONFIG" | grep "REGISTRY_PDA=" | cut -d'=' -f2)
MARKET_PDA=$(echo "$PDA_CONFIG" | grep "MARKET_PDA=" | cut -d'=' -f2)

if [ -z "$ENERGY_TOKEN_MINT" ]; then
    echo -e "${RED}Failed to derive PDA addresses. Output: $PDA_CONFIG${NC}"
    exit 1
fi

echo -e "${CYAN}  Energy Mint: $ENERGY_TOKEN_MINT${NC}"
echo -e "${CYAN}  Registry:    $REGISTRY_PDA${NC}"
echo -e "${CYAN}  Market:      $MARKET_PDA${NC}"
echo -e "${GREEN}✅ Blockchain state initialized${NC}"

# ============================================================================
# Step 7: Update .env files with derived configuration
# ============================================================================
echo ""
echo -e "${YELLOW}📝 Updating environment configuration...${NC}"

# Update gateway .env
update_env_file "$GATEWAY_DIR/.env" "ENERGY_TOKEN_MINT" "$ENERGY_TOKEN_MINT"
update_env_file "$GATEWAY_DIR/.env" "SOLANA_RPC_URL" "$RPC_URL"
update_env_file "$GATEWAY_DIR/.env" "SOLANA_WS_URL" "$WS_URL"
update_env_file "$GATEWAY_DIR/.env" "AUTHORITY_WALLET_PATH" "dev-wallet.json"
# Add extra derived IDs if needed by gateway
update_env_file "$GATEWAY_DIR/.env" "REGISTRY_PDA" "$REGISTRY_PDA"
update_env_file "$GATEWAY_DIR/.env" "TRADING_MARKET_PDA" "$MARKET_PDA"

# Update project root .env
update_env_file "$PROJECT_ROOT/.env" "ENERGY_TOKEN_MINT" "$ENERGY_TOKEN_MINT"
update_env_file "$PROJECT_ROOT/.env" "SOLANA_RPC_URL" "$RPC_URL"
update_env_file "$PROJECT_ROOT/.env" "SOLANA_WS_URL" "$WS_URL"

# Update trading frontend .env
TRADING_ENV="$PROJECT_ROOT/gridtokenx-trading/.env"
if [ -f "$TRADING_ENV" ]; then
    update_env_file "$TRADING_ENV" "NEXT_PUBLIC_ENERGY_TOKEN_MINT" "$ENERGY_TOKEN_MINT"
    update_env_file "$TRADING_ENV" "NEXT_PUBLIC_SOLANA_RPC_URL" "$RPC_URL"
fi

echo -e "${GREEN}✅ Environment configured${NC}"


# ============================================================================
# Step 8: Start Application Services (New Terminals)
# ============================================================================
echo ""
echo -e "${YELLOW}🚀 Launching application services...${NC}"

# Check for node_modules in frontend projects
if [ -d "$PROJECT_ROOT/gridtokenx-admin" ]; then
    if [ ! -d "$PROJECT_ROOT/gridtokenx-admin/node_modules" ]; then
        echo -e "${YELLOW}Warning: gridtokenx-admin/node_modules missing. Skipping Admin UI.${NC}"
    fi
fi
if [ ! -d "$PROJECT_ROOT/gridtokenx-trading/node_modules" ]; then
    echo -e "${RED}Error: gridtokenx-trading/node_modules missing. Please run 'bun install' or 'bun install' in gridtokenx-trading.${NC}"
    exit 1
fi

# Function to run command in new terminal window
run_in_new_terminal() {
    local title="$1"
    local command="$2"
    local dir="$3"
    
    echo "  • Starting $title..."
    # AppleScript to open new window and run command
    osascript -e "tell application \"Terminal\" to do script \"cd $dir && $command\"" >/dev/null
}

# 1. API Gateway (Debug build for speed)
run_in_new_terminal "API Gateway" "cargo run --bin api-gateway" "$GATEWAY_DIR"

# 2. Smart Meter Simulator (Frontend)
run_in_new_terminal "Simulator UI" "bun run dev" "$PROJECT_ROOT/gridtokenx-smartmeter-simulator"

# 3. Smart Meter Simulator (Python API)
run_in_new_terminal "Simulator API" "source .venv/bin/activate && export PYTHONPATH=\$PYTHONPATH:src && python -m uvicorn app.app:app --reload --host 0.0.0.0 --port 8000" "$PROJECT_ROOT/gridtokenx-smartmeter-simulator"

# 4. Trading UI
run_in_new_terminal "Trading UI" "bun run dev" "$PROJECT_ROOT/gridtokenx-trading"

# 5. Admin UI
# 5. Admin UI
if [ -d "$PROJECT_ROOT/gridtokenx-admin" ] && [ -d "$PROJECT_ROOT/gridtokenx-admin/node_modules" ]; then
    run_in_new_terminal "Admin UI" "bun run dev" "$PROJECT_ROOT/gridtokenx-admin"
fi

# 6. Tail Validator Logs
run_in_new_terminal "Validator Logs" "tail -f $PROJECT_ROOT/scripts/logs/validator.log" "$PROJECT_ROOT"

echo ""
echo -e "${YELLOW}NOTE: Services are running in separate Terminal windows.${NC}"
echo -e "${YELLOW}To stop them, you can close the windows or run ./scripts/stop-dev.sh${NC}"

# Disown validator so it stays running if we exit
disown $VALIDATOR_PID
echo ""
echo -e "${GREEN}✅ Development environment launched!${NC}"
echo ""
echo -e "${BLUE}📡 Service Endpoints:${NC}"
echo -e "  • Solana RPC:      ${CYAN}http://localhost:8899${NC}"
echo -e "  • API Gateway:     ${CYAN}http://localhost:4000${NC}"
echo -e "  • Simulator API:   ${CYAN}http://localhost:8000${NC}"
echo -e "  • Simulator UI:    ${CYAN}http://localhost:8080${NC} (or similar, check terminal)"
echo -e "  • Trading UI:      ${CYAN}http://localhost:3000${NC}"
echo -e "  • Admin UI:        ${CYAN}http://localhost:3001${NC} (or similar, check terminal)"
echo ""
echo -e "${YELLOW}👉 Check the opened Terminal windows for logs and actual frontend ports if different.${NC}"

