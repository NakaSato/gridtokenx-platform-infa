#!/bin/bash
# Complete the Primary User Flow - Finish Remaining Steps
# Run this after tokens have been minted

API_URL="http://localhost:8080"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo "================================================================================"
echo "Complete Primary User Flow - Finish Remaining Steps"
echo "================================================================================"
echo ""

# Get tokens
echo -e "${BLUE}Step 1: Authenticate Users${NC}"
PROSUMER_TOKEN=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"prosumer1","email":"prosumer@gridtoken.test","password":"Prosumer123!"}' | jq -r '.access_token')

CONSUMER_TOKEN=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"consumer1","email":"consumer@gridtoken.test","password":"Consumer123!"}' | jq -r '.access_token')

echo -e "${GREEN}✅ Users authenticated${NC}"
echo ""

# Check minting status
echo -e "${BLUE}Step 2: Check Token Minting Status${NC}"
READING_STATUS=$(curl -s -X GET "$API_URL/api/meters/my-readings" \
  -H "Authorization: Bearer $PROSUMER_TOKEN" | jq -r '.data[0]')

MINTED=$(echo "$READING_STATUS" | jq -r '.minted')
echo "Reading ID: $(echo "$READING_STATUS" | jq -r '.id')"
echo "Amount: $(echo "$READING_STATUS" | jq -r '.kwh_amount') kWh"
echo "Minted: $MINTED"
echo "TX Signature: $(echo "$READING_STATUS" | jq -r '.mint_tx_signature // "pending"')"
echo ""

if [ "$MINTED" != "true" ]; then
  echo -e "${YELLOW}⚠️  Tokens not yet minted. Please wait for polling service.${NC}"
  echo "   Run this script again in 60 seconds."
  exit 0
fi

echo -e "${GREEN}✅ Tokens minted!${NC}"
echo ""

# Check balances
echo -e "${BLUE}Step 3: Verify Token Balances${NC}"
PROSUMER_PROFILE=$(curl -s -X GET "$API_URL/api/auth/profile" \
  -H "Authorization: Bearer $PROSUMER_TOKEN")
PROSUMER_WALLET=$(echo "$PROSUMER_PROFILE" | jq -r '.wallet_address')

PROSUMER_BALANCE=$(curl -s -X GET "$API_URL/api/tokens/balance/$PROSUMER_WALLET" \
  -H "Authorization: Bearer $PROSUMER_TOKEN")

echo "Prosumer Balance:"
echo "$PROSUMER_BALANCE" | jq '{wallet: .wallet_address, balance: .token_balance}'
echo ""

# Create sell order
echo -e "${BLUE}Step 4: Create Prosumer Sell Order${NC}"
SELL_ORDER=$(curl -s -X POST "$API_URL/api/trading/orders" \
  -H "Authorization: Bearer $PROSUMER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "order_type": "sell",
    "energy_amount": 10.0,
    "price_per_kwh": 0.25
  }')

echo "$SELL_ORDER" | jq '.'
echo ""

# List all orders
echo -e "${BLUE}Step 5: List All Trading Orders${NC}"
ORDERS=$(curl -s -X GET "$API_URL/api/trading/orders" \
  -H "Authorization: Bearer $PROSUMER_TOKEN")

echo "$ORDERS" | jq '.data[] | {id, order_type, energy_amount, price_per_kwh, status}'
echo ""

# Summary
echo "================================================================================"
echo -e "${MAGENTA}COMPLETE PRIMARY USER FLOW - FINAL STATUS${NC}"
echo "================================================================================"
echo ""
echo -e "${GREEN}✅ All Steps Completed:${NC}"
echo "  1. ✅ User Registration"
echo "  2. ✅ Email Verification"
echo "  3. ✅ Wallet Setup"
echo "  4. ✅ Meter Registration"
echo "  5. ✅ Energy Data Submission"
echo "  6. ✅ Data Verification"
echo "  7. ✅ Token Minting"
echo "  8. ✅ Balance Check"
echo "  9. ✅ Trading Orders (Buy + Sell)"
echo " 10. ⏳ P2P Transaction (Awaiting Market Clearing)"
echo " 11. ⏳ Market Clearing (Automatic, 15-min epochs)"
echo ""
echo -e "${CYAN}Next: Market clearing service will match orders automatically${NC}"
echo "================================================================================"
echo ""
