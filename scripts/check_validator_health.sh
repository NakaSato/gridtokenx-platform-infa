#!/bin/bash

# Default URL (can be overridden)
RPC_URL=${1:-"http://localhost:8899"}

echo "Checking Solana Validator Health at $RPC_URL..."

# Perform the same check as API Gateway (getHealth)
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0", "id":1, "method":"getHealth"}' $RPC_URL)

if [ $? -ne 0 ]; then
    echo "❌ Failed to connect to validator at $RPC_URL"
    exit 1
fi

# Check if response contains "result": "ok"
if [[ $RESPONSE == *'"result":"ok"'* ]]; then
    echo "✅ Validator is HEALTHY"
    echo "Response: $RESPONSE"
    exit 0
else
    echo "⚠️  Validator returned unexpected response"
    echo "Response: $RESPONSE"
    exit 1
fi
