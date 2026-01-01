#!/bin/bash
# =============================================================================
# GridTokenX Local Development Deployment Script
# =============================================================================
# This script handles the complete local development environment setup:
# 1. Starts Solana test validator
# 2. Funds the development wallet
# 3. Builds and deploys Anchor programs
# 4. Creates SPL token with dev-wallet as mint authority
# 5. Updates API Gateway configuration
# 6. Starts all services
# =============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ANCHOR_DIR="$PROJECT_ROOT/gridtokenx-anchor"
API_GATEWAY_DIR="$PROJECT_ROOT/gridtokenx-apigateway"
TRADING_DIR="$PROJECT_ROOT/gridtokenx-trading"
DEV_WALLET_PATH="$ANCHOR_DIR/keypairs/dev-wallet.json"
RPC_URL="http://localhost:8899"

# Print section header
header() {
    echo ""
    echo -e "${BLUE}==============================================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}==============================================================================${NC}"
}

# Print status message
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Print warning
warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Print error
error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if a process is running on a port
is_port_in_use() {
    lsof -i :$1 > /dev/null 2>&1
}

# Wait for Solana validator to be ready
wait_for_validator() {
    info "Waiting for Solana validator to be ready..."
    for i in {1..30}; do
        if solana cluster-version --url $RPC_URL > /dev/null 2>&1; then
            info "Solana validator is ready!"
            return 0
        fi
        sleep 1
    done
    error "Solana validator failed to start"
    return 1
}

# Get dev wallet address
get_dev_wallet_address() {
    solana-keygen pubkey "$DEV_WALLET_PATH" 2>/dev/null
}

# =============================================================================
# STEP 1: Start Solana Test Validator
# =============================================================================
start_validator() {
    header "Step 1: Starting Solana Test Validator"
    
    if is_port_in_use 8899; then
        warn "Solana validator already running on port 8899"
    else
        info "Starting Solana test validator..."
        cd "$ANCHOR_DIR"
        solana-test-validator --reset > /dev/null 2>&1 &
        wait_for_validator
    fi
}

# =============================================================================
# STEP 2: Fund Dev Wallet
# =============================================================================
fund_wallet() {
    header "Step 2: Funding Development Wallet"
    
    DEV_WALLET=$(get_dev_wallet_address)
    info "Dev wallet address: $DEV_WALLET"
    
    BALANCE=$(solana balance "$DEV_WALLET" --url $RPC_URL 2>/dev/null | awk '{print $1}')
    info "Current balance: $BALANCE SOL"
    
    if (( $(echo "$BALANCE < 100" | bc -l) )); then
        info "Airdropping 200 SOL to dev wallet..."
        solana airdrop 200 "$DEV_WALLET" --url $RPC_URL
    else
        info "Wallet has sufficient balance"
    fi
}

# =============================================================================
# STEP 3: Build Anchor Programs
# =============================================================================
build_anchor() {
    header "Step 3: Building Anchor Programs"
    
    cd "$ANCHOR_DIR"
    info "Building Anchor programs..."
    anchor build
}

# =============================================================================
# STEP 4: Deploy Anchor Programs
# =============================================================================
deploy_anchor() {
    header "Step 4: Deploying Anchor Programs"
    
    cd "$ANCHOR_DIR"
    info "Deploying programs to localnet..."
    anchor deploy --provider.cluster localnet --provider.wallet ./keypairs/dev-wallet.json
    
    # Extract deployed program IDs
    info "Reading deployed program IDs..."
    ORACLE_PROGRAM_ID=$(solana program show --programs --url $RPC_URL 2>/dev/null | grep -E "^[A-Za-z0-9]{43,44}" | head -1 | awk '{print $1}')
    
    # Read from Anchor.toml for correct program IDs
    REGISTRY_PROGRAM_ID=$(grep -A1 '\[programs.localnet\]' Anchor.toml | grep registry | sed 's/.*= "\(.*\)"/\1/')
    ORACLE_PROGRAM_ID=$(grep -A5 '\[programs.localnet\]' Anchor.toml | grep oracle | head -1 | sed 's/.*= "\(.*\)"/\1/')
    GOVERNANCE_PROGRAM_ID=$(grep -A10 '\[programs.localnet\]' Anchor.toml | grep governance | sed 's/.*= "\(.*\)"/\1/')
    ENERGY_TOKEN_PROGRAM_ID=$(grep -A15 '\[programs.localnet\]' Anchor.toml | grep energy_token | sed 's/.*= "\(.*\)"/\1/')
    TRADING_PROGRAM_ID=$(grep -A20 '\[programs.localnet\]' Anchor.toml | grep trading | head -1 | sed 's/.*= "\(.*\)"/\1/')
    
    info "Deployed Programs:"
    info "  Registry: $REGISTRY_PROGRAM_ID"
    info "  Oracle: $ORACLE_PROGRAM_ID"
    info "  Governance: $GOVERNANCE_PROGRAM_ID"
    info "  Energy Token: $ENERGY_TOKEN_PROGRAM_ID"
    info "  Trading: $TRADING_PROGRAM_ID"
}

# =============================================================================
# STEP 5: Create SPL Token
# =============================================================================
create_spl_token() {
    header "Step 5: Creating SPL Energy Token"
    
    cd "$API_GATEWAY_DIR"
    
    info "Creating SPL token with dev-wallet as mint authority..."
    TOKEN_OUTPUT=$(spl-token create-token --decimals 6 --url $RPC_URL --fee-payer "$DEV_WALLET_PATH" 2>&1)
    
    ENERGY_TOKEN_MINT=$(echo "$TOKEN_OUTPUT" | grep "Address:" | awk '{print $2}')
    info "Created Energy Token Mint: $ENERGY_TOKEN_MINT"
    
    export ENERGY_TOKEN_MINT
}

# =============================================================================
# STEP 6: Update API Gateway Configuration
# =============================================================================
update_api_config() {
    header "Step 6: Updating API Gateway Configuration"
    
    cd "$API_GATEWAY_DIR"
    
    if [ -z "$ENERGY_TOKEN_MINT" ]; then
        error "ENERGY_TOKEN_MINT not set. Run create_spl_token first."
        return 1
    fi
    
    info "Updating .env file..."
    
    # Backup existing .env
    cp .env .env.backup 2>/dev/null || true
    
    # Update ENERGY_TOKEN_MINT
    if grep -q "ENERGY_TOKEN_MINT=" .env; then
        sed -i.bak "s/ENERGY_TOKEN_MINT=.*/ENERGY_TOKEN_MINT=$ENERGY_TOKEN_MINT/" .env
    else
        echo "ENERGY_TOKEN_MINT=$ENERGY_TOKEN_MINT" >> .env
    fi
    
    # Update program IDs if available
    if [ -n "$ENERGY_TOKEN_PROGRAM_ID" ]; then
        sed -i.bak "s/SOLANA_ENERGY_TOKEN_PROGRAM_ID=.*/SOLANA_ENERGY_TOKEN_PROGRAM_ID=$ENERGY_TOKEN_PROGRAM_ID/" .env
    fi
    
    rm -f .env.bak
    
    info "Configuration updated successfully"
    info "  ENERGY_TOKEN_MINT=$ENERGY_TOKEN_MINT"
}

# =============================================================================
# STEP 7: Start Services
# =============================================================================
start_services() {
    header "Step 7: Starting Services"
    
    # Start API Gateway
    if is_port_in_use 4000; then
        warn "API Gateway already running on port 4000"
    else
        info "Starting API Gateway..."
        cd "$API_GATEWAY_DIR"
        cargo run --bin api-gateway > /tmp/api-gateway.log 2>&1 &
        sleep 5
        if is_port_in_use 4000; then
            info "API Gateway started successfully"
        else
            error "API Gateway failed to start. Check /tmp/api-gateway.log"
        fi
    fi
    
    # Start Trading Frontend
    if is_port_in_use 3000; then
        warn "Trading frontend already running on port 3000"
    else
        info "Starting Trading frontend..."
        cd "$TRADING_DIR"
        npm run dev > /tmp/trading-ui.log 2>&1 &
        sleep 5
        if is_port_in_use 3000; then
            info "Trading frontend started successfully"
        else
            error "Trading frontend failed to start. Check /tmp/trading-ui.log"
        fi
    fi
}

# =============================================================================
# Print Summary
# =============================================================================
print_summary() {
    header "Deployment Summary"
    
    DEV_WALLET=$(get_dev_wallet_address)
    
    echo ""
    echo -e "  ${GREEN}✓${NC} Solana Validator:  http://localhost:8899"
    echo -e "  ${GREEN}✓${NC} API Gateway:       http://localhost:4000"
    echo -e "  ${GREEN}✓${NC} Trading UI:        http://localhost:3000"
    echo ""
    echo "  Dev Wallet: $DEV_WALLET"
    echo "  Token Mint: ${ENERGY_TOKEN_MINT:-Not created}"
    echo ""
    echo "  Test Users:"
    echo "    Buyer:  buyer@gridtokenx.com / Buyer123!"
    echo "    Seller: seller@gridtokenx.com / Seller123!"
    echo ""
}

# =============================================================================
# Main Entry Point
# =============================================================================
main() {
    header "GridTokenX Local Deployment"
    
    case "${1:-all}" in
        validator)
            start_validator
            ;;
        fund)
            fund_wallet
            ;;
        build)
            build_anchor
            ;;
        deploy)
            deploy_anchor
            ;;
        token)
            create_spl_token
            ;;
        config)
            update_api_config
            ;;
        services)
            start_services
            ;;
        all)
            start_validator
            fund_wallet
            build_anchor
            deploy_anchor
            create_spl_token
            update_api_config
            start_services
            print_summary
            ;;
        *)
            echo "Usage: $0 {validator|fund|build|deploy|token|config|services|all}"
            echo ""
            echo "Commands:"
            echo "  validator  - Start Solana test validator"
            echo "  fund       - Fund dev wallet with SOL"
            echo "  build      - Build Anchor programs"
            echo "  deploy     - Deploy Anchor programs"
            echo "  token      - Create SPL energy token"
            echo "  config     - Update API Gateway configuration"
            echo "  services   - Start API Gateway and Trading UI"
            echo "  all        - Run all steps (default)"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
