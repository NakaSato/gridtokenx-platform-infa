#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== GridTokenX Blockchain Initialization ===${NC}"

# Check for Anchor
if ! command -v anchor &> /dev/null; then
    echo -e "${RED}Error: anchor CLI is not installed.${NC}"
    echo "Please install it from https://www.anchor-lang.com/docs/installation"
    exit 1
fi

# Check for Solana
if ! command -v solana &> /dev/null; then
    echo -e "${RED}Error: solana CLI is not installed.${NC}"
    exit 1
fi

PROJECT_ROOT=$(pwd)
ANCHOR_DIR="$PROJECT_ROOT/gridtokenx-anchor"

# 1. Build Anchor Programs
echo -e "${GREEN}1. Building Anchor Programs...${NC}"
cd "$ANCHOR_DIR"
# We skip the "Deploying" part of anchor build if validator isn't running perfectly, 
# but "anchor build" generates the .so files we need.
anchor build --verifiable

# 2. Check Validator Status
echo -e "${GREEN}2. Checking Local Validator...${NC}"
RPC_URL="http://localhost:8899"
if curl -s $RPC_URL/health > /dev/null; then
    echo "Validator is reachable at $RPC_URL"
else
    echo -e "${RED}Validator is NOT reachable.${NC}"
    echo "Please run 'docker-compose up -d solana-test-validator' or 'solana-test-validator' natively."
    # We don't exit here because sometimes we just want to build
    read -p "Continue without deploying? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 3. Deploy Programs
echo -e "${GREEN}3. Deploying Programs...${NC}"

# Function to deploy if not exists
deploy_program() {
    local NAME=$1
    local ID=$2
    
    echo "Deploying $NAME ($ID)..."
    solana program deploy \
        --program-id "$ANCHOR_DIR/target/deploy/$NAME-keypair.json" \
        "$ANCHOR_DIR/target/deploy/$NAME.so" \
        --url $RPC_URL || echo "Deployment failed or already exists"
}

# Values from Anchor.toml / Source of Truth
deploy_program "registry" "EgpmmYPFDAX8QfawUEFissBXi3yG6AapoxNfB6KdGtBQ"
deploy_program "energy_token" "G8dC1NwdDiMhfrnPwkf9dMaR2AgrnFXcjWcepyGSHTfA"
deploy_program "trading" "CrfC5coUm2ty6DphLBFhAmr8m1AMutf8KTW2JYS38Z5J"
deploy_program "oracle" "4Agkm8isGD6xDegsfoFzWN5Xp5WLVoqJyPDQLRsjh85u"
deploy_program "governance" "3d1BQT3EiwbspkD8HYKAnyLvKjs5kZwSbRBWwS5NHof9"

echo -e "${GREEN}4. Initialization Complete!${NC}"
echo "You can now run 'docker-compose up' to start the application stack."
