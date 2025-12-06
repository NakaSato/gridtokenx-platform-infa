#!/bin/bash
set -e

# 1. Start Solana Validator
echo "Starting Solana Validator..."
# Check if already running
if pgrep -x "solana-test-validator" > /dev/null; then
    echo "Validator already running. Killing it..."
    pkill -x "solana-test-validator"
    sleep 2
fi

solana-test-validator --reset --quiet > validator.log 2>&1 &
VALIDATOR_PID=$!
echo "Validator PID: $VALIDATOR_PID"

# Wait for validator
echo "Waiting for validator to start..."
sleep 5
MAX_RETRIES=30
COUNT=0
until solana cluster-version > /dev/null 2>&1; do
  echo "Waiting for validator... ($COUNT/$MAX_RETRIES)"
  sleep 2
  COUNT=$((COUNT+1))
  if [ $COUNT -ge $MAX_RETRIES ]; then
    echo "Validator failed to start."
    cat validator.log
    exit 1
  fi
done
echo "Validator is ready."

# 2. Airdrop to Authority Wallet
if [ ! -f dev-wallet.json ]; then
    echo "dev-wallet.json not found! Generating one..."
    solana-keygen new --outfile dev-wallet.json --no-bip39-passphrase
fi

AUTHORITY_PUBKEY=$(solana-keygen pubkey dev-wallet.json)
echo "Authority Pubkey: $AUTHORITY_PUBKEY"
echo "Airdropping SOL..."
solana airdrop 10 $AUTHORITY_PUBKEY

# 3. Create Token Mint
echo "Creating Energy Token Mint..."
# Create a new keypair for the mint
solana-keygen new --outfile energy-mint.json --no-bip39-passphrase --force
# Create token using spl-token CLI
# Output format: "Creating token <ADDRESS>"
OUTPUT=$(spl-token create-token --mint-authority dev-wallet.json energy-mint.json)
echo "$OUTPUT"
MINT_ADDRESS=$(echo "$OUTPUT" | grep "Creating token" | awk '{print $3}')

if [ -z "$MINT_ADDRESS" ]; then
    echo "Failed to extract mint address."
    exit 1
fi
echo "New Mint Address: $MINT_ADDRESS"

# 4. Update docker-compose.yml
echo "Updating docker-compose.yml..."
# Use perl for in-place editing to avoid sed differences between Mac/Linux
perl -i -pe "s/ENERGY_TOKEN_MINT: .*/ENERGY_TOKEN_MINT: $MINT_ADDRESS/" docker-compose.yml

# 5. Restart API Gateway
echo "Restarting API Gateway..."
docker-compose restart apigateway
# Wait for it to be healthy
echo "Waiting for API Gateway to restart..."
sleep 15

# 6. Run Test Script
echo "Running Test Script..."
./test_mint_flow.sh

# Cleanup
echo "Stopping Validator..."
kill $VALIDATOR_PID
