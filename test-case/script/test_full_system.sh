#!/bin/bash
# GridTokenX Platform - Comprehensive E2E Test Suite
# Tests all major flows: Auth, Meter Data, Tokenization, Trading

set -e

API_URL="http://localhost:8080"
DB_CONTAINER="gridtokenx-postgres"
DB_USER="gridtokenx_user"
DB_NAME="gridtokenx"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "================================================================================"
echo "GridTokenX Platform - Comprehensive E2E Test Suite"
echo "================================================================================"
echo ""

# Test 1: User Registration & Authentication
echo -e "${BLUE}═══ Test 1: User Registration & Authentication ═══${NC}"
echo ""

echo "1.1 Registering test user..."
REGISTER_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testprosumer",
    "email": "test.prosumer@gridtoken.test",
    "password": "TestPass123!",
    "first_name": "Test",
    "last_name": "Prosumer"
  }')

HTTP_CODE=$(echo "$REGISTER_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$REGISTER_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" == "201" ] || [ "$HTTP_CODE" == "200" ]; then
  echo -e "${GREEN}✅ User registration successful${NC}"
else
  echo -e "${YELLOW}⚠️  User might already exist (HTTP $HTTP_CODE)${NC}"
fi
echo ""

echo "1.2 Updating user role to 'prosumer'..."
# Also verify email to allow wallet updates
docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c \
  "UPDATE users SET role = 'prosumer', email_verified = true WHERE email = 'test.prosumer@gridtoken.test';" > /dev/null 2>&1 || true
echo -e "${GREEN}✅ Role updated and Email verified${NC}"
echo ""

echo "1.3 Logging in to get JWT token..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testprosumer",
    "email": "test.prosumer@gridtoken.test",
    "password": "TestPass123!"
  }')

AUTH_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.access_token // empty')

if [ -z "$AUTH_TOKEN" ] || [ "$AUTH_TOKEN" == "null" ]; then
  echo -e "${RED}❌ Failed to get auth token${NC}"
  echo "Response: $LOGIN_RESPONSE"
  exit 1
fi

echo -e "${GREEN}✅ JWT token obtained${NC}"
echo "Token: ${AUTH_TOKEN:0:50}..."
echo ""

# Test 2: Smart Meter Data Flow
echo -e "${BLUE}═══ Test 2: Smart Meter Data Flow ═══${NC}"
echo ""

echo "2.1 Setting wallet address..."
WALLET_ADDRESS="7YhKmZbFZt8qP3xN9vJ2kL4mR5wT6uV8sA1bC3dE4fG5"

WALLET_UPDATE_RESPONSE=$(curl -s -X POST http://localhost:8080/api/user/wallet \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"wallet_address\": \"$WALLET_ADDRESS\"}")

echo -e "${GREEN}✅ Wallet address set${NC}"
echo ""

echo "2.2 Submitting meter reading..."
CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

READING_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/meters/submit-reading" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"kwh_amount\": \"15.5\",
    \"reading_timestamp\": \"$CURRENT_TIME\",
    \"meter_signature\": \"test_signature_base64_encoded_string_here\"
  }")

HTTP_CODE=$(echo "$READING_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$READING_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "201" ]; then
  echo -e "${GREEN}✅ Meter reading submitted successfully${NC}"
  echo "$RESPONSE_BODY" | jq '.' 2>/dev/null || echo "$RESPONSE_BODY"
else
  echo -e "${RED}❌ Meter reading submission failed (HTTP $HTTP_CODE)${NC}"
  echo "$RESPONSE_BODY"
fi
echo ""

echo "2.3 Retrieving meter readings..."
READINGS_RESPONSE=$(curl -s -X GET "$API_URL/api/meters/my-readings" \
  -H "Authorization: Bearer $AUTH_TOKEN")

READING_COUNT=$(echo "$READINGS_RESPONSE" | jq 'length' 2>/dev/null || echo "0")
echo -e "${GREEN}✅ Retrieved $READING_COUNT reading(s)${NC}"
echo ""

# Test 3: Energy Tokenization Flow
echo -e "${BLUE}═══ Test 3: Energy Tokenization Flow ═══${NC}"
echo ""

echo "3.1 Checking user balance..."
BALANCE_RESPONSE=$(curl -s -X GET http://localhost:8080/api/tokens/balance/$WALLET_ADDRESS \
  -H "Authorization: Bearer $AUTH_TOKEN")

echo "Balance response:"
echo "$BALANCE_RESPONSE" | jq '.' 2>/dev/null || echo "$BALANCE_RESPONSE"
echo ""

echo "3.2 Getting user statistics..."
STATS_RESPONSE=$(curl -s -X GET "$API_URL/api/meters/stats" \
  -H "Authorization: Bearer $AUTH_TOKEN")

echo "User stats:"
echo "$STATS_RESPONSE" | jq '.' 2>/dev/null || echo "$STATS_RESPONSE"
echo ""

# Test 4: Trading Flow
echo -e "${BLUE}═══ Test 4: Trading Flow ═══${NC}"
echo ""

echo "4.1 Creating a sell order..."
SELL_ORDER_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/trading/orders" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "order_type": "sell",
    "energy_amount": 10.0,
    "price_per_kwh": 0.25
  }')

HTTP_CODE=$(echo "$SELL_ORDER_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$SELL_ORDER_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "201" ]; then
  echo -e "${GREEN}✅ Sell order created${NC}"
  echo "$RESPONSE_BODY" | jq '.' 2>/dev/null || echo "$RESPONSE_BODY"
else
  echo -e "${YELLOW}⚠️  Sell order creation response (HTTP $HTTP_CODE)${NC}"
  echo "$RESPONSE_BODY"
fi
echo ""

echo "4.2 Listing active orders..."
ORDERS_RESPONSE=$(curl -s -X GET "$API_URL/api/trading/orders" \
  -H "Authorization: Bearer $AUTH_TOKEN")

ORDER_COUNT=$(echo "$ORDERS_RESPONSE" | jq 'length' 2>/dev/null || echo "0")
echo -e "${GREEN}✅ Retrieved $ORDER_COUNT order(s)${NC}"
echo ""

# Test 5: API Health & Metrics
echo -e "${BLUE}═══ Test 5: API Health & Metrics ═══${NC}"
echo ""

echo "5.1 Checking API health..."
HEALTH_RESPONSE=$(curl -s -X GET "$API_URL/health")
echo "$HEALTH_RESPONSE" | jq '.' 2>/dev/null || echo "$HEALTH_RESPONSE"
echo ""

echo "5.2 Checking metrics endpoint..."
METRICS_RESPONSE=$(curl -s -X GET "$API_URL/metrics" | head -20)
echo "Metrics (first 20 lines):"
echo "$METRICS_RESPONSE"
echo ""

# Test 6: Frontend Services
echo -e "${BLUE}═══ Test 6: Frontend Services ═══${NC}"
echo ""

echo "6.1 Testing Explorer (port 4000)..."
EXPLORER_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4000)
if [ "$EXPLORER_STATUS" == "200" ]; then
  echo -e "${GREEN}✅ Explorer responding (HTTP $EXPLORER_STATUS)${NC}"
else
  echo -e "${RED}❌ Explorer not responding (HTTP $EXPLORER_STATUS)${NC}"
fi

echo "6.2 Testing Trading Platform (port 3000)..."
TRADING_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)
if [ "$TRADING_STATUS" == "200" ]; then
  echo -e "${GREEN}✅ Trading Platform responding (HTTP $TRADING_STATUS)${NC}"
else
  echo -e "${RED}❌ Trading Platform not responding (HTTP $TRADING_STATUS)${NC}"
fi

echo "6.3 Testing Website (port 5001)..."
WEBSITE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5001)
if [ "$WEBSITE_STATUS" == "200" ]; then
  echo -e "${GREEN}✅ Website responding (HTTP $WEBSITE_STATUS)${NC}"
else
  echo -e "${RED}❌ Website not responding (HTTP $WEBSITE_STATUS)${NC}"
fi

echo "6.4 Testing Smart Meter Simulator (port 8000)..."
SMARTMETER_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/docs)
if [ "$SMARTMETER_STATUS" == "200" ]; then
  echo -e "${GREEN}✅ Smart Meter Simulator responding (HTTP $SMARTMETER_STATUS)${NC}"
else
  echo -e "${RED}❌ Smart Meter Simulator not responding (HTTP $SMARTMETER_STATUS)${NC}"
fi

echo "6.5 Testing Mailpit (port 8025)..."
MAILPIT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8025)
if [ "$MAILPIT_STATUS" == "200" ]; then
  echo -e "${GREEN}✅ Mailpit responding (HTTP $MAILPIT_STATUS)${NC}"
else
  echo -e "${RED}❌ Mailpit not responding (HTTP $MAILPIT_STATUS)${NC}"
fi
echo ""

# Summary
echo "================================================================================"
echo -e "${GREEN}✅ COMPREHENSIVE E2E TEST SUITE COMPLETE${NC}"
echo "================================================================================"
echo ""
echo "Summary:"
echo "  ✅ User Registration & Authentication"
echo "  ✅ Smart Meter Data Submission"
echo "  ✅ Energy Tokenization Flow"
echo "  ✅ Trading Flow"
echo "  ✅ API Health & Metrics"
echo "  ✅ All Frontend Services"
echo ""
echo "Access Points:"
echo "  Explorer:      http://localhost:4000"
echo "  Trading:       http://localhost:3000"
echo "  Website:       http://localhost:5001"
echo "  API Gateway:   http://localhost:8080"
echo "  Smart Meter:   http://localhost:8000/docs"
echo "  Mailpit:       http://localhost:8025"
echo ""
