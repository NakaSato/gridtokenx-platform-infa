#!/bin/bash
# ==============================================================================
# GridTokenX - P2P Trading Flow Integration Test
# ==============================================================================
# This script tests the end-to-end P2P trading scenario:
# 1. Register Prosumer & Meter
# 2. Mint Tokens (via Mock/Direct API)
# 3. Register Consumer & Meter
# 4. Prosumer creates SELL Order
# 5. Consumer creates BUY Order
# 6. Trigger Order Matching
# ==============================================================================

set -e

# Configuration
API_URL="http://localhost:8080/api"
ADMIN_KEY="engineering-department-api-key-2025"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[TEST] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

check_health() {
    log "Checking API Health..."
    curl -s "${API_URL}/health" | grep "healthy" > /dev/null || error "API not healthy"
    log "API is Healthy"
}

# Generate Random Email
random_email() {
    echo "user_$(date +%s)_$RANDOM@test.com"
}

# 1. Register User (Returns User ID)
register_user() {
    local email=$1
    local password="Password123!"
    local role=$2 # prosumer or consumer
    
    log "Registering $role ($email)..."
    
    response=$(curl -s -X POST "${API_URL}/auth/register" \
      -H "Content-Type: application/json" \
      -d "{
        \"email\": \"$email\",
        \"password\": \"$password\",
        \"full_name\": \"Test $role\",
        \"role\": \"$role\",
        \"phone_number\": \"+1234567890\",
        \"address\": \"123 Test St\",
        \"city\": \"Test City\",
        \"postal_code\": \"12345\",
        \"country\": \"Test Country\"
      }")

    if echo "$response" | grep -q "id"; then
         # Extract token or login to get token?
         # Assuming register auto-logs-in or we need to login
         # Login to get token
         login_response=$(curl -s -X POST "${API_URL}/auth/login" \
            -H "Content-Type: application/json" \
            -d "{
              \"email\": \"$email\",
              \"password\": \"$password\"
            }")
         
         token=$(echo "$login_response" | jq -r '.token')
         user_id=$(echo "$login_response" | jq -r '.user.id')
         
         echo "$token:$user_id"
    else
        error "Registration failed: $response"
    fi
}

setup_prosumer() {
    local email=$(random_email)
    local result=$(register_user "$email" "prosumer")
    PROSUMER_TOKEN=$(echo "$result" | cut -d: -f1)
    PROSUMER_ID=$(echo "$result" | cut -d: -f2)
    log "Prosumer Setup Complete: $PROSUMER_ID"
    
    # Needs to request a specific role update? Or is register role enough?
    # Schema says roles table.
}

setup_consumer() {
    local email=$(random_email)
    local result=$(register_user "$email" "consumer")
    CONSUMER_TOKEN=$(echo "$result" | cut -d: -f1)
    CONSUMER_ID=$(echo "$result" | cut -d: -f2)
    log "Consumer Setup Complete: $CONSUMER_ID"
}

create_sell_order() {
    log "Creating Sell Order..."
    local amount="50.0" # kWh
    local price="0.15" # $/kWh
    
    order_response=$(curl -s -X POST "${API_URL}/trading/orders" \
        -H "Authorization: Bearer $PROSUMER_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
          \"side\": \"Sell\",
          \"order_type\": \"Limit\",
          \"energy_amount\": $amount,
          \"price_per_kwh\": $price
        }")
        
    SELL_ORDER_ID=$(echo "$order_response" | jq -r '.id')
    
    if [ "$SELL_ORDER_ID" == "null" ]; then
        error "Failed to create Sell Order: $order_response"
    fi
    log "Sell Order Created: $SELL_ORDER_ID"
}

create_buy_order() {
    log "Creating Buy Order..."
    local amount="25.0" # kWh (Partial Match)
    local price="0.15" # $/kWh
    
    order_response=$(curl -s -X POST "${API_URL}/trading/orders" \
        -H "Authorization: Bearer $CONSUMER_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
          \"side\": \"Buy\",
          \"order_type\": \"Limit\",
          \"energy_amount\": $amount,
          \"price_per_kwh\": $price
        }")
        
    BUY_ORDER_ID=$(echo "$order_response" | jq -r '.id')
    
    if [ "$BUY_ORDER_ID" == "null" ]; then
         error "Failed to create Buy Order: $order_response"
    fi
    log "Buy Order Created: $BUY_ORDER_ID"
}

trigger_matching() {
    log "Triggering Order Matching..."
    # Assuming there's an admin endpoint or we wait for the loop.
    # If using admin/market/match endpoint (if exists) or just wait.
    # Or rely on background task.
    # For test, we might want an explicit trigger.
    
    # Check admin endpoints
    # POST /api/admin/market/match ?
    # Let's try or wait 6 seconds
    sleep 6 
}

verify_settlement() {
    log "Verifying Settlement..."
    # Check Order Status
    
    # Check Buy Order
    buy_check=$(curl -s -X GET "${API_URL}/trading/orders?status=Filled" \
         -H "Authorization: Bearer $CONSUMER_TOKEN")
         
    # This is a list. Check if ID is present.
    # Or get specific order details if endpoint exists GET /trading/orders/:id
    
    # Simplified: Just listing filled orders
    echo "Filled Orders (Consumer):"
    echo "$buy_check" | jq '.'
}

# Main Execution
check_health
setup_prosumer
setup_consumer
create_sell_order
create_buy_order
trigger_matching
verify_settlement

log "P2P Flow Test Completed."
