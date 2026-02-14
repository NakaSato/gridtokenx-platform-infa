#!/bin/bash
set -e

# Configuration
RPC_URL="http://127.0.0.1:8899"
WS_URL="ws://127.0.0.1:8900"
PROJECT_ROOT="/Users/chanthawat/Developments/gridtokenx-platform-infa"
GATEWAY_DIR="$PROJECT_ROOT/gridtokenx-apigateway"
DEV_WALLET="$GATEWAY_DIR/dev-wallet.json"

# Helper to update env
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

echo "Creating Energy Token..."

# Create Token
TOKEN_OUTPUT=$(spl-token create-token \
    --program-id TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb \
    --enable-permanent-delegate \
    --decimals 9 \
    --fee-payer "$DEV_WALLET" \
    --mint-authority "$DEV_WALLET" \
    --url $RPC_URL 2>&1)

ENERGY_TOKEN_MINT=$(echo "$TOKEN_OUTPUT" | grep "Address:" | awk '{print $2}')

if [ -z "$ENERGY_TOKEN_MINT" ]; then
    echo "Failed to create token. Output: $TOKEN_OUTPUT"
    exit 1
fi

echo "Token Mint: $ENERGY_TOKEN_MINT"
echo "Dev Wallet (Authority): $(solana-keygen pubkey $DEV_WALLET)"

echo "Updating .env files..."

# Update Gateway .env
update_env_file "$GATEWAY_DIR/.env" "ENERGY_TOKEN_MINT" "$ENERGY_TOKEN_MINT"
update_env_file "$GATEWAY_DIR/.env" "SOLANA_RPC_URL" "$RPC_URL"
update_env_file "$GATEWAY_DIR/.env" "SOLANA_WS_URL" "$WS_URL"
update_env_file "$GATEWAY_DIR/.env" "AUTHORITY_WALLET_PATH" "dev-wallet.json"

# Update Root .env
update_env_file "$PROJECT_ROOT/.env" "ENERGY_TOKEN_MINT" "$ENERGY_TOKEN_MINT"
update_env_file "$PROJECT_ROOT/.env" "SOLANA_RPC_URL" "$RPC_URL"
update_env_file "$PROJECT_ROOT/.env" "SOLANA_WS_URL" "$WS_URL"

# Update Trading .env
TRADING_ENV="$PROJECT_ROOT/gridtokenx-trading/.env"
if [ -f "$TRADING_ENV" ]; then
    update_env_file "$TRADING_ENV" "NEXT_PUBLIC_ENERGY_TOKEN_MINT" "$ENERGY_TOKEN_MINT"
fi

echo "Done!"
