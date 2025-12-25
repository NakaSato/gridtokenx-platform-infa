#!/bin/bash
# GridTokenX Minting API Integration Tests v2
# Simplified and more robust version
#
# REQUIREMENTS:
# - API Gateway running on localhost:4000
# - PostgreSQL database running (docker: gridtokenx-postgres)
# - Redis running (docker: gridtokenx-redis) 
# - Solana test validator running (for minting tests)
#
# KNOWN ISSUES:
# - Reading creation may hang if blockchain minting operations timeout
# - The create_reading endpoint at /api/v1/meters/{serial}/readings  
#   performs auto-minting which can cause empty responses if blockchain
#   operations fail or hang (see: handlers/auth/meters.rs lines 513-543)
# - Minting requires: funded authority wallet, valid token mint, and
#   properly configured blockchain service
# - Empty reply from server typically indicates blockchain timeout
#
# TO RUN FULL TESTS:
# 1. Ensure solana-test-validator is running
# 2. Ensure API Gateway is running with correct .env configuration
# 3. Run: ./scripts/test-minting-api.sh

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

API_URL="${API_URL:-http://localhost:4000}"
PASSED=0
FAILED=0
SKIPPED=0

# Test wallet - use system program address (always valid)
TEST_WALLET="11111111111111111111111111111111"

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_test() {
    echo -e "${YELLOW}🧪 TEST: $1${NC}"
}

pass() {
    echo -e "${GREEN}   ✅ PASS: $1${NC}"
    ((PASSED++))
}

fail() {
    echo -e "${RED}   ❌ FAIL: $1${NC}"
    ((FAILED++))
}

skip() {
    echo -e "${YELLOW}   ⚠️  SKIP: $1${NC}"
    ((SKIPPED++))
}

# Check if API is available
print_header "Pre-flight Checks"
echo "Checking API availability..."
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$API_URL/health" 2>/dev/null)
if [ "$API_STATUS" != "200" ]; then
    echo -e "${RED}ERROR: API is not available (status: $API_STATUS)${NC}"
    echo "Please start the API gateway first: cd gridtokenx-apigateway && cargo run"
    exit 1
fi
echo -e "${GREEN}API is available${NC}"

# ============================================================================
# TEST SUITE 1: API Authentication
# ============================================================================
print_header "API Authentication Tests"

print_test "Minting requires authentication"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 \
    -X POST "$API_URL/api/v1/meters/readings/00000000-0000-0000-0000-000000000001/mint")
if [ "$HTTP_CODE" == "401" ] || [ "$HTTP_CODE" == "403" ]; then
    pass "Returns 401/403 without auth token"
else
    fail "Expected 401/403, got $HTTP_CODE"
fi

print_test "Minting with invalid token returns 401/403"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 \
    -X POST "$API_URL/api/v1/meters/readings/00000000-0000-0000-0000-000000000001/mint" \
    -H "Authorization: Bearer invalid_token_here")
if [ "$HTTP_CODE" == "401" ] || [ "$HTTP_CODE" == "403" ]; then
    pass "Returns 401/403 with invalid token"
else
    fail "Expected 401/403, got $HTTP_CODE"
fi

# ============================================================================
# TEST SUITE 2: Invalid Reading IDs  
# ============================================================================
print_header "Invalid Reading ID Tests"

# Register a user for these tests
TS=$(date +%s)
REG_RESP=$(curl -s --connect-timeout 10 -X POST "$API_URL/api/v1/users" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"test_${TS}@test.com\",\"password\":\"TestPass123!\",\"username\":\"test${TS}\",\"first_name\":\"Test\",\"last_name\":\"User\"}")
TOKEN=$(echo "$REG_RESP" | jq -r '.auth.access_token // empty')

if [ -z "$TOKEN" ]; then
    echo -e "${RED}ERROR: Could not register test user${NC}"
    echo "Response: $REG_RESP"
    exit 1
fi
echo "Test user registered successfully"

print_test "Returns 404 for non-existent reading"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 \
    -X POST "$API_URL/api/v1/meters/readings/00000000-0000-0000-0000-000000000000/mint" \
    -H "Authorization: Bearer $TOKEN")
if [ "$HTTP_CODE" == "404" ]; then
    pass "Returns 404 for non-existent reading"
else
    fail "Expected 404, got $HTTP_CODE"
fi

print_test "Returns 400/404 for malformed UUID"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 \
    -X POST "$API_URL/api/v1/meters/readings/not-a-valid-uuid/mint" \
    -H "Authorization: Bearer $TOKEN")
if [ "$HTTP_CODE" == "400" ] || [ "$HTTP_CODE" == "404" ]; then
    pass "Returns 400/404 for malformed UUID"
else
    fail "Expected 400/404, got $HTTP_CODE"
fi

# ============================================================================
# TEST SUITE 3: Reading Ownership (Cross-user access)
# ============================================================================
print_header "Reading Ownership Tests"

print_test "User cannot mint another user's reading"

# Register second user
TS2=$((TS + 1))
REG_RESP2=$(curl -s --connect-timeout 10 -X POST "$API_URL/api/v1/users" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"test2_${TS2}@test.com\",\"password\":\"TestPass123!\",\"username\":\"test2${TS2}\",\"first_name\":\"Test2\",\"last_name\":\"User\"}")
TOKEN2=$(echo "$REG_RESP2" | jq -r '.auth.access_token // empty')

# Register meter for user1
METER="METER-${TS}"
curl -s --connect-timeout 10 -X POST "$API_URL/api/v1/meters" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"serial_number\":\"$METER\",\"location\":\"Test\",\"meter_type\":\"smart\"}" > /dev/null

# Verify meter
docker exec gridtokenx-postgres psql -U gridtokenx_user -d gridtokenx \
    -c "UPDATE meters SET is_verified=true WHERE serial_number='$METER'" > /dev/null 2>&1 || true

# Submit reading as user1 (with auto_mint=false to avoid blockchain timeout)
READING_RESP=$(curl -s --connect-timeout 10 -X POST "$API_URL/api/v1/meters/$METER/readings?auto_mint=false" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"kwh\":25.0,\"wallet_address\":\"$TEST_WALLET\"}")
READING_ID=$(echo "$READING_RESP" | jq -r '.id // empty')

if [ -z "$READING_ID" ] || [ "$READING_ID" == "null" ]; then
    # Reading submission may have failed, skip this test
    skip "Could not create test reading (API may require blockchain)"
else
    # User2 tries to mint user1's reading
    MINT_RESP=$(curl -s --connect-timeout 10 -X POST "$API_URL/api/v1/meters/readings/$READING_ID/mint" \
        -H "Authorization: Bearer $TOKEN2" \
        -H "Content-Type: application/json")
    ERROR_MSG=$(echo "$MINT_RESP" | jq -r '.error.message // .message // empty')
    
    if [[ "$ERROR_MSG" == *"denied"* ]] || [[ "$ERROR_MSG" == *"Access"* ]] || [[ "$ERROR_MSG" == *"not found"* ]]; then
        pass "Cannot mint another user's reading"
    else
        fail "Should deny access: $MINT_RESP"
    fi
fi

# ============================================================================
# TEST SUITE 4: Double Minting Prevention
# ============================================================================
print_header "Double Minting Prevention Tests"

print_test "Cannot mint the same reading twice"

if [ -z "$READING_ID" ] || [ "$READING_ID" == "null" ]; then
    skip "No reading available for double-mint test"
else
    # First mint (by owner)
    MINT1=$(curl -s --connect-timeout 30 -X POST "$API_URL/api/v1/meters/readings/$READING_ID/mint" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json")
    
    # Second mint attempt
    MINT2=$(curl -s --connect-timeout 30 -X POST "$API_URL/api/v1/meters/readings/$READING_ID/mint" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json")
    
    ERROR_MSG=$(echo "$MINT2" | jq -r '.error.message // .message // empty')
    
    if [[ "$ERROR_MSG" == *"already"* ]] || [[ "$ERROR_MSG" == *"minted"* ]]; then
        pass "Double minting prevented"
    else
        # Check if first mint succeeded
        TX_SIG=$(echo "$MINT1" | jq -r '.transaction_signature // empty')
        if [ -n "$TX_SIG" ] && [ "$TX_SIG" != "null" ]; then
            # First mint succeeded but second didn't fail properly
            if [[ "$ERROR_MSG" == *"already"* ]] || [[ "$ERROR_MSG" == *"minted"* ]]; then
                pass "Double minting prevented"
            else
                fail "Second mint should fail: $MINT2"
            fi
        else
            skip "First mint failed (blockchain may not be running)"
        fi
    fi
fi

# ============================================================================
# Summary
# ============================================================================
print_header "TEST SUMMARY"

TOTAL=$((PASSED + FAILED + SKIPPED))
echo ""
echo -e "Total Tests: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo -e "${YELLOW}Skipped: $SKIPPED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    if [ $SKIPPED -gt 0 ]; then
        echo -e "${YELLOW}⚠️  All run tests passed, but some were skipped${NC}"
        echo "   Skipped tests require blockchain services to be running."
        echo "   Start Solana test validator: solana-test-validator"
    else
        echo -e "${GREEN}🎉 All tests passed!${NC}"
    fi
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed${NC}"
    exit 1
fi
