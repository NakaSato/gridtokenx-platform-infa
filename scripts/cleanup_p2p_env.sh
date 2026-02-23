#!/bin/bash

# Cleanup script for GridTokenX P2P Environment
# Cancels all active orders in the order book

set -e

API_URL="${API_URL:-http://localhost:4000}"
TIMESTAMP=$(date +%s)

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; exit 1; }
log_info() { echo -e "🔍 $1"; }

echo "🧼 Cleaning up P2P Environment (Timestamp: $TIMESTAMP)"

# 1. Try to perform cleanup via API first (better for logic/refunds)
log_info "Attempting API-based cleanup..."
ADMIN_EMAIL="cleanup_admin_$TIMESTAMP@test.com"
ADMIN_RESP=$(curl -s -X POST "$API_URL/api/v1/users" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$ADMIN_EMAIL\",
        \"password\": \"CleanupP@ss123!\",
        \"username\": \"cleanup_admin_$TIMESTAMP\",
        \"first_name\": \"Cleanup\",
        \"last_name\": \"Admin\"
    }")

# Extract token and wallet
ADMIN_TOKEN=$(echo "$ADMIN_RESP" | jq -r '.data.auth.access_token // .auth.access_token // empty')
ADMIN_WALLET=$(echo "$ADMIN_RESP" | jq -r '.data.wallet_address // .wallet_address // empty')

if [ -z "$ADMIN_TOKEN" ] || [ "$ADMIN_TOKEN" == "null" ]; then
    log_info "Could not create admin via API. Falling back to database cleanup..."
else
    if [ -z "$ADMIN_WALLET" ] || [ "$ADMIN_WALLET" == "null" ]; then
        # Try users/me
        USER_ME=$(curl -s -X GET "$API_URL/api/v1/users/me" -H "Authorization: Bearer $ADMIN_TOKEN")
        ADMIN_WALLET=$(echo "$USER_ME" | jq -r '.data.wallet_address // .wallet_address // empty')
    fi

    if [ -n "$ADMIN_WALLET" ] && [ "$ADMIN_WALLET" != "null" ]; then
        # Promote
        curl -s -X POST "$API_URL/api/v1/dev/faucet" \
            -H "Content-Type: application/json" \
            -d "{
                \"wallet_address\": \"$ADMIN_WALLET\",
                \"amount_sol\": 1.0,
                \"promote_to_role\": \"admin\"
            }" > /dev/null
        
        # Cancel orders
        log_info "Fetching active orders..."
        ORDER_IDS=$(curl -s -X GET "$API_URL/api/v1/orderbook" -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.data[]?.id // empty')
        
        for ID in $ORDER_IDS; do
            curl -s -X DELETE "$API_URL/api/v1/orders/$ID" -H "Authorization: Bearer $ADMIN_TOKEN" > /dev/null
            echo "  Cancelled $ID"
        done
    fi
fi

# 2. Force Cleanup via Database (covers orphans and ensures clean state)
if command -v docker >/dev/null 2>&1 && docker ps | grep -q "gridtokenx-postgres"; then
    log_info "Executing database-level cleanup for ALL active orders..."
    # Target 'active' and 'partially_filled' as they are the ones showing up in the book
    docker exec gridtokenx-postgres psql -U gridtokenx_user -d gridtokenx -c "UPDATE trading_orders SET status = 'cancelled', updated_at = NOW() WHERE status IN ('active', 'partially_filled', 'pending');" > /dev/null
    docker exec gridtokenx-postgres psql -U gridtokenx_user -d gridtokenx -c "UPDATE escrow_records SET status = 'released', updated_at = NOW() WHERE status = 'locked';" > /dev/null
    log_success "Database cleanup executed (Cleared active orders)"
else
    log_warn "Docker or Postgres container not found. Database cleanup skipped."
fi

# 3. Final Verification
log_info "Verifying cleanup..."
VERIFY_BOOK=$(curl -s -X GET "$API_URL/api/v1/orderbook")
REMAINING=$(echo "$VERIFY_BOOK" | jq -r '.data | length // 0')

if [ "$REMAINING" -eq 0 ]; then
    log_success "Cleanup successful! Order book is empty."
else
    log_error "Cleanup failed: $REMAINING orders still active."
fi

echo "============================================"
log_success "Cleanup process finished"
echo "============================================"
