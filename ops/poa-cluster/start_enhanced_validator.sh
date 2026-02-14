#!/bin/bash
set -e

# Configuration
CLUSTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$CLUSTER_DIR/validator.log"
LEDGER_DIR="$CLUSTER_DIR/test-ledger"

echo "Starting Enhanced Solana Test Validator..."
echo "  - Cloning feature set from Devnet"
echo "  - Logs: $LOG_FILE"
echo "  - Ledger: $LEDGER_DIR"

# Ensure we have a clean slate if requested (optional, but good for reproducibility)
# rm -rf "$LEDGER_DIR"

# Start validator
# --url devnet: Source for feature set cloning
# --clone-feature-set: Copies feature activation status from Devnet
# --reset: Resets ledger to genesis
# --quiet: Reduces stdout noise (logs go to file)
solana-test-validator \
    --reset \
    --url devnet \
    --clone-feature-set \
    --ledger "$LEDGER_DIR" \
    --log > "$LOG_FILE" 2>&1 &

VALIDATOR_PID=$!
echo "Validator process started with PID: $VALIDATOR_PID"
echo "Waiting for validator to become ready..."

# Wait loop
for i in {1..60}; do
    if solana cluster-version --url http://127.0.0.1:8899 &>/dev/null; then
        echo "✅ Validator is ready!"
        exit 0
    fi
    sleep 2
done

echo "❌ Validator failed to start within 120 seconds."
echo "Check logs at $LOG_FILE"
kill $VALIDATOR_PID 2>/dev/null || true
exit 1
