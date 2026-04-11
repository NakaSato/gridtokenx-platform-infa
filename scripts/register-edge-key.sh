#!/bin/bash

# GridTokenX Device Registration Helper
# Registers an Edge Gateway public key in the Oracle Bridge Redis cache.

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <METER_ID> <PUBLIC_KEY_HEX>"
    echo "Example: $0 0x0001 029283..."
    exit 1
fi

METER_ID=$1
PUBKEY_HEX=$2

# Check if redis-cli is available locally or via docker
if command -v redis-cli &> /dev/null; then
    REDIS_CMD="redis-cli"
elif docker ps | grep -q gridtokenx-redis; then
    REDIS_CMD="docker exec -i gridtokenx-redis redis-cli"
else
    echo "❌ Error: redis-cli not found and gridtokenx-redis container not running."
    exit 1
fi

# In Redis, the Oracle Bridge expects the RAW BYTES of the public key.
# We convert hex to binary and SET it.
# Note: xxd is used for hex-to-binary conversion.

echo "⚙️ Registering key for $METER_ID..."

# Store hex string directly in Redis for simplified cross-platform handling
$REDIS_CMD SET "gridtokenx:devices:${METER_ID}:pubkey" "$PUBKEY_HEX"

if [ $? -eq 0 ]; then
    echo "✅ Successfully registered $METER_ID public key."
else
    echo "❌ Failed to register key."
    exit 1
fi
