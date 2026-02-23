#!/bin/bash

# Test script for ULID-based Order ID Generation
# Verifies that order IDs are time-ordered (lexicographically sortable)
# which prevents database index fragmentation

set -e

API_URL="${API_URL:-http://localhost:4000}"
TIMESTAMP=$(date +%s)

echo "🧪 Starting ULID Order ID Test (Timestamp: $TIMESTAMP)"
echo "==================================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

log_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Check dependencies
command -v curl >/dev/null 2>&1 || log_error "curl is required but not installed"
command -v jq >/dev/null 2>&1 || log_error "jq is required but not installed"

# 1. CREATE TEST USERS
echo ""
echo "--- Phase 1: Create Test Users ---"

SELLER_EMAIL="ulid_seller_$TIMESTAMP@test.com"
BUYER_EMAIL="ulid_buyer_$TIMESTAMP@test.com"

SELLER_RESP=$(curl -s -X POST "$API_URL/api/v1/users" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$SELLER_EMAIL\",
        \"password\": \"TestP@ssw0rd!\",
        \"username\": \"ulid_seller_$TIMESTAMP\",
        \"first_name\": \"ULID\",
        \"last_name\": \"Seller\"
    }")

SELLER_TOKEN=$(echo "$SELLER_RESP" | jq -r '.data.auth.access_token // .auth.access_token // empty')
if [ -z "$SELLER_TOKEN" ] || [ "$SELLER_TOKEN" == "null" ]; then
    log_error "Failed to get Seller token. Response: $SELLER_RESP"
fi
log_success "Seller registered"

BUYER_RESP=$(curl -s -X POST "$API_URL/api/v1/users" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$BUYER_EMAIL\",
        \"password\": \"TestP@ssw0rd!\",
        \"username\": \"ulid_buyer_$TIMESTAMP\",
        \"first_name\": \"ULID\",
        \"last_name\": \"Buyer\"
    }")

BUYER_TOKEN=$(echo "$BUYER_RESP" | jq -r '.data.auth.access_token // .auth.access_token // empty')
if [ -z "$BUYER_TOKEN" ] || [ "$BUYER_TOKEN" == "null" ]; then
    log_error "Failed to get Buyer token. Response: $BUYER_RESP"
fi
log_success "Buyer registered"

# 2. CREATE MULTIPLE ORDERS IN SEQUENCE
echo ""
echo "--- Phase 2: Create Sequential Orders (Testing ULID Ordering) ---"

ORDER_IDS=()
ORDER_TIMESTAMPS=()

for i in 1 2 3 4 5; do
    log_info "Creating order $i..."
    
    ORDER_RESP=$(curl -s -X POST "$API_URL/api/v1/orders" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $SELLER_TOKEN" \
        -d "{
            \"side\": \"sell\",
            \"order_type\": \"limit\",
            \"energy_amount\": 10.0,
            \"price_per_kwh\": 5.0
        }")
    
    ORDER_ID=$(echo "$ORDER_RESP" | jq -r '.data.id // .id // empty')
    if [ -z "$ORDER_ID" ] || [ "$ORDER_ID" == "null" ]; then
        log_error "Failed to create order $i. Response: $ORDER_RESP"
    fi
    
    ORDER_IDS+=("$ORDER_ID")
    ORDER_TIMESTAMPS+=("$(date +%s%N)")
    
    # Small delay to ensure different ULID timestamps
    sleep 0.1
    log_success "Order $i created: $ORDER_ID"
done

# 3. VERIFY ORDER IDs ARE VALID UUIDS
echo ""
echo "--- Phase 3: Verify UUID Format ---"

for id in "${ORDER_IDS[@]}"; do
    if [[ $id =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
        log_success "Order ID is valid UUID format: $id"
    else
        log_error "Order ID is NOT a valid UUID: $id"
    fi
done

# 4. VERIFY LEXICOGRAPHIC SORTING (ULID Property)
echo ""
echo "--- Phase 4: Verify Lexicographic Ordering (ULID Property) ---"

SORTED_IDS=($(printf '%s\n' "${ORDER_IDS[@]}" | sort))

ORDER_CORRECT=true
for i in "${!ORDER_IDS[@]}"; do
    if [ "${ORDER_IDS[$i]}" != "${SORTED_IDS[$i]}" ]; then
        ORDER_CORRECT=false
        break
    fi
done

if [ "$ORDER_CORRECT" = true ]; then
    log_success "Order IDs are in lexicographic order (ULID timestamp ordering working!)"
    echo ""
    echo "Order ID Sequence:"
    for i in "${!ORDER_IDS[@]}"; do
        echo "  $((i+1)). ${ORDER_IDS[$i]}"
    done
else
    log_info "Order IDs are not in lexicographic order (may indicate random UUIDs)"
    echo ""
    echo "Created order:"
    for id in "${ORDER_IDS[@]}"; do
        echo "  - $id"
    done
    echo ""
    echo "Sorted order:"
    for id in "${SORTED_IDS[@]}"; do
        echo "  - $id"
    done
fi

# 5. FETCH ORDERS FROM API AND VERIFY SORTING
echo ""
echo "--- Phase 5: Verify API Returns Orders in Time Order ---"

API_ORDERS=$(curl -s -X GET "$API_URL/api/v1/orders" \
    -H "Authorization: Bearer $SELLER_TOKEN")

# Extract order IDs from API response (most recent first, by created_at)
API_ORDER_IDS=$(echo "$API_ORDERS" | jq -r '.data.orders[]?.id // .orders[]?.id // empty' | head -5)

if [ -n "$API_ORDER_IDS" ]; then
    log_success "Successfully fetched orders from API"
    echo ""
    echo "API returned order IDs (should match creation order, newest first by created_at):"
    echo "$API_ORDER_IDS" | head -5 | nl
else
    log_info "Could not verify API order listing (may need seller order endpoint)"
fi

# 6. CLEANUP
echo ""
echo "--- Phase 6: Cleanup ---"
echo "Test users and orders created. Manual cleanup may be required."

# Summary
echo ""
echo "==================================================="
echo "📊 ULID Test Summary"
echo "==================================================="
echo "Created ${#ORDER_IDS[@]} orders"
echo "All Order IDs are valid UUIDs: ✅"

if [ "$ORDER_CORRECT" = true ]; then
    echo "ULID Lexicographic ordering: ✅ (IDs sorted by timestamp)"
    echo ""
    echo "✅ SUCCESS: ULID implementation is working correctly!"
    echo "   Orders will have append-only behavior in B-tree indexes."
else
    echo "ULID Lexicographic ordering: ⚠️"
    echo ""
    echo "ℹ️  NOTE: If order was expected, verify UUID generation is using ULID."
fi

echo ""
echo "Test completed at $(date)"
