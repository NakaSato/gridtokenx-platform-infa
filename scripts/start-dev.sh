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

# Start validator in background with reset
solana-test-validator --reset --quiet &
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
# Step 6: Create Energy Token (Standard SPL Token)
# ============================================================================
echo ""
echo -e "${YELLOW}🪙 Creating Energy Token (SPL Token)...${NC}"
cd "$GATEWAY_DIR"

# Create a new SPL token with dev-wallet as mint authority (9 decimals)
# Using Token-2022 with Permanent Delegate to allow authority to burn tokens from user wallets
TOKEN_OUTPUT=$(spl-token create-token \
    --program-2022 \
    --enable-permanent-delegate \
    --decimals 9 \
    --fee-payer "$DEV_WALLET" \
    --mint-authority "$DEV_WALLET" \
    --url $RPC_URL 2>&1)

# Extract the token address
ENERGY_TOKEN_MINT=$(echo "$TOKEN_OUTPUT" | grep "Address:" | awk '{print $2}')

if [ -z "$ENERGY_TOKEN_MINT" ]; then
    echo -e "${RED}Failed to create token. Output: $TOKEN_OUTPUT${NC}"
    exit 1
fi

echo -e "${CYAN}  Token Mint: $ENERGY_TOKEN_MINT${NC}"
echo -e "${CYAN}  Authority:  $DEV_PUBKEY${NC}"
echo -e "${GREEN}✅ Energy Token created${NC}"

# ============================================================================
# Step 7: Update .env files with token configuration
# ============================================================================
echo ""
echo -e "${YELLOW}📝 Updating environment configuration...${NC}"

# Update gateway .env
update_env_file "$GATEWAY_DIR/.env" "ENERGY_TOKEN_MINT" "$ENERGY_TOKEN_MINT"
update_env_file "$GATEWAY_DIR/.env" "SOLANA_RPC_URL" "$RPC_URL"
update_env_file "$GATEWAY_DIR/.env" "SOLANA_WS_URL" "$WS_URL"
update_env_file "$GATEWAY_DIR/.env" "AUTHORITY_WALLET_PATH" "dev-wallet.json"

# Update project root .env
update_env_file "$PROJECT_ROOT/.env" "ENERGY_TOKEN_MINT" "$ENERGY_TOKEN_MINT"
update_env_file "$PROJECT_ROOT/.env" "SOLANA_RPC_URL" "$RPC_URL"
update_env_file "$PROJECT_ROOT/.env" "SOLANA_WS_URL" "$WS_URL"

echo -e "${GREEN}✅ Environment configured${NC}"

# ============================================================================
# Step 8: Build API Gateway (if needed)
# ============================================================================
echo ""
echo -e "${YELLOW}🔨 Building API Gateway...${NC}"
cd "$GATEWAY_DIR"

cargo build --release --bin api-gateway 2>&1 | tail -5
echo -e "${GREEN}✅ API Gateway built${NC}"

# ============================================================================
# Step 9: Start API Gateway
# ============================================================================
echo ""
echo -e "${YELLOW}🚀 Starting API Gateway...${NC}"
cd "$GATEWAY_DIR"

# Export environment variables and start
export $(grep -v '^#' .env | grep -v "^$" | xargs)
./target/release/api-gateway 2>&1 &
GATEWAY_PID=$!
echo "  API Gateway PID: $GATEWAY_PID"

# Wait for API to be ready
echo -e "${YELLOW}⏳ Waiting for API Gateway to be ready...${NC}"
for i in {1..60}; do
    if curl -s http://localhost:4000/health | grep -q "healthy"; then
        echo -e "${GREEN}✅ API Gateway is ready!${NC}"
        break
    fi
    sleep 1
done

# ============================================================================
# Step 10: Seed Simulator Accounts
# ============================================================================
echo ""
echo -e "${YELLOW}planting seeds for simulator accounts...${NC}"
"$PROJECT_ROOT/scripts/seed_simulator_tokens.sh" || echo -e "${RED}Warning: Failed to seed simulator tokens${NC}"


# ============================================================================
# Final Summary
# ============================================================================
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Development Environment Ready!           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Services running:${NC}"
echo "  • Solana Validator:  $RPC_URL"
echo "  • API Gateway:       http://localhost:4000"
echo "  • Swagger Docs:      http://localhost:4000/api/docs"
echo "  • PostgreSQL:        localhost:5432"
echo "  • Redis:             localhost:6379"
echo ""
echo -e "${CYAN}Token Configuration:${NC}"
echo "  • Energy Token Mint: $ENERGY_TOKEN_MINT"
echo "  • Mint Authority:    $DEV_PUBKEY"
echo ""
echo -e "${YELLOW}Key Endpoints:${NC}"
echo "  • Register User:     POST /api/v1/users"
echo "  • Login:             POST /api/v1/auth/token"
echo "  • Register Meter:    POST /api/v1/meters"
echo "  • Submit Reading:    POST /api/v1/meters/{serial}/readings"
echo "  • Mint Tokens:       POST /api/v1/meters/readings/{id}/mint"
echo "  • Check Balance:     GET /api/v1/wallets/{address}/balance"
echo ""
echo -e "${YELLOW}To stop all services:${NC}"
echo "  pkill -f solana-test-validator"
echo "  pkill -f api-gateway"
echo ""
echo -e "${GREEN}Happy coding! 🎉${NC}"
