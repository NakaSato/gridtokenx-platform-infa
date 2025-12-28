#!/bin/bash
# Seed Simulator Token Accounts
# Mints initial tokens to simulator accounts to prevent "Insufficient Funds" errors

set -e

# Configuration
RPC_URL="http://localhost:8899"
SCRIPT_DIR="$(dirname "$0")"
# Try absolute path first, then relative to script
if [ -f "gridtokenx-apigateway/dev-wallet.json" ]; then
    DEV_WALLET="gridtokenx-apigateway/dev-wallet.json"
elif [ -f "$SCRIPT_DIR/../gridtokenx-apigateway/dev-wallet.json" ]; then
    DEV_WALLET="$SCRIPT_DIR/../gridtokenx-apigateway/dev-wallet.json"
else
     # Fallback to assumming we are in project root
    DEV_WALLET="gridtokenx-apigateway/dev-wallet.json"
fi
MINT_ADDRESS=$(grep "ENERGY_TOKEN_MINT" .env | cut -d '=' -f2)

if [ -z "$MINT_ADDRESS" ]; then
    echo "Error: ENERGY_TOKEN_MINT not found in .env"
    exit 1
fi

echo "Seeding simulator accounts with tokens..."
echo "Mint: $MINT_ADDRESS"

# List of simulator wallet addresses
# Derived from simulator/src/smart_meter_simulator/services/meter_service.py and observed logs
ACCOUNTS=(
    "2dWUzgUDM9e6UBCdMjYjvimaBuopengXLspQytrSHcwg" # Seller
    "Et1cJEPVW4jiJGrC4dFA4GhTfBeBenMuMzjZc1WLnuXX" # Buyer
    "Fa3FHRjY1QxE9mc2NhJoGcSMsRuV83eBYVUEdt5Py7Xv" # Sim Meter 001
    "AmeT4PvH96gx8AiuLkpjsX9ExA21oH2HtthgbvzDgnD3" # Default fallback
    "CNCaQynULxLiVgvG8Am9Ptxh48ob3QA2wEaM7YhU5jRs" # Persistent Simulator Wallet 1
    "HMNycQ2LrCBCMscVfGRjPvQawhZihpWqgTWoCdJitFSt" # Persistent Simulator Wallet 2
)

AMOUNT=1000

for wallet in "${ACCOUNTS[@]}"; do
    echo "Funding $wallet with $AMOUNT GRX..."
    
    # Create ATA if not exists (idempotent)
    spl-token create-account "$MINT_ADDRESS" \
        --owner "$wallet" \
        --fee-payer "$DEV_WALLET" \
        --program-2022 \
        --url "$RPC_URL" >/dev/null 2>&1 || true

    # Mint tokens
    spl-token mint "$MINT_ADDRESS" "$AMOUNT" \
        --recipient-owner "$wallet" \
        --mint-authority "$DEV_WALLET" \
        --fee-payer "$DEV_WALLET" \
        --program-2022 \
        --url "$RPC_URL"
done

echo "✅ Seeding complete!"
