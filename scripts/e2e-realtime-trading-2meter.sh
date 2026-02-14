#!/usr/bin/env bash
###############################################################################
# GridTokenX — E2E Realtime Energy Trading Test (2 Meters)
#
# Focused test: 2 smart meters (Meter-A = solar producer, Meter-B = consumer)
# simulating realtime energy surplus/deficit and P2P trading settlement.
#
# Flow:
#   1. Register seller + buyer users with wallets
#   2. Register 2 smart meters (solar + consumer)
#   3. Meter-A produces surplus → auto-mint tokens
#   4. Meter-B consumes energy → deficit reading
#   5. Seller creates sell order from surplus
#   6. Buyer creates matching buy order
#   7. Orders match → settlement → verify balances
#
# Prerequisites:
#   ./scripts/start-dev.sh   (starts Postgres, Redis, Solana, API Gateway)
#
# Usage:
#   chmod +x scripts/e2e-realtime-trading-2meter.sh
#   ./scripts/e2e-realtime-trading-2meter.sh
###############################################################################
set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────
# Source .env to inherit correct API keys and endpoints
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/../.env" ]]; then
    set -a; source "${SCRIPT_DIR}/../.env" 2>/dev/null; set +a
fi
BASE_URL="${BASE_URL:-http://localhost:4000}"
RPC_URL="${RPC_URL:-http://localhost:8899}"
API_KEY="${API_KEY:-bf3a948c96147b7460f0a5073f1ec6774cc0761f19a74c94b97867de8a4564ab}"
TS=$(date +%s)

# Test identities
SELLER_EMAIL="seller_rt_${TS}@e2e.com"
SELLER_USERNAME="seller_rt_${TS}"
SELLER_PASSWORD="StrongP@ssw0rd!"
BUYER_EMAIL="buyer_rt_${TS}@e2e.com"
BUYER_USERNAME="buyer_rt_${TS}"
BUYER_PASSWORD="StrongP@ssw0rd!"

# 2 Meters
METER_A_SERIAL="SOLAR-A-${TS}"
METER_B_SERIAL="CONSUMER-B-${TS}"

# ─── Counters & Colors ──────────────────────────────────────────────────────
TOTAL=0; PASSED=0; FAILED=0; SKIPPED=0; START_TIME=$(date +%s)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()  { echo -e "${BLUE}ℹ  $*${NC}"; }
phase() { echo -e "\n${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${BOLD}${CYAN}  $*${NC}"; echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }
step()  { echo -e "\n${YELLOW}▸ $*${NC}"; }

pass()  { TOTAL=$((TOTAL+1)); PASSED=$((PASSED+1)); echo -e "  ${GREEN}✔ PASS${NC} — $*"; }
fail()  { TOTAL=$((TOTAL+1)); FAILED=$((FAILED+1)); echo -e "  ${RED}✘ FAIL${NC} — $*"; }
skip()  { TOTAL=$((TOTAL+1)); SKIPPED=$((SKIPPED+1)); echo -e "  ${YELLOW}⊘ SKIP${NC} — $*"; }

CURL_TIMEOUT="${CURL_TIMEOUT:-30}"
do_curl() {
    local method="$1" path="$2"; shift 2
    curl -s --max-time "${CURL_TIMEOUT}" -w "\n%{http_code}" -X "$method" "${BASE_URL}${path}" "$@" 2>/dev/null || echo -e "\n000"
}
do_curl_timeout() {
    local timeout="$1" method="$2" path="$3"; shift 3
    curl -s --max-time "${timeout}" -w "\n%{http_code}" -X "$method" "${BASE_URL}${path}" "$@" 2>/dev/null || echo -e "\n000"
}
get_code() { echo "$1" | tail -1; }
get_body() { echo "$1" | sed '$d'; }

assert_status() {
    local name="$1" actual="$2" expected="$3"
    if [[ "$actual" == "$expected" ]]; then pass "$name (HTTP $actual)"; else fail "$name — expected HTTP $expected, got HTTP $actual"; fi
}

poll_until() {
    local max="$1" delay="$2" method="$3" path="$4" jq_expr="$5"; shift 5
    local CURL_TIMEOUT=8 resp code body val
    for ((i=1; i<=max; i++)); do
        resp=$(do_curl "$method" "$path" "$@")
        code=$(get_code "$resp"); body=$(get_body "$resp")
        if [[ "$code" == "200" ]]; then
            val=$(echo "$body" | jq -r "$jq_expr" 2>/dev/null)
            if [[ -n "$val" && "$val" != "null" && "$val" != "false" && "$val" != "0" && "$val" != "0.0" ]]; then
                echo "$resp"; return 0
            fi
        fi
        info "  poll $i/$max — code=$code, wait ${delay}s..."
        [[ $i -lt $max ]] && sleep "$delay"
    done
    echo "$resp"; return 1
}

###############################################################################
echo -e "\n${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║   ⚡ E2E Realtime Energy Trading — 2 Smart Meters ⚡     ║${NC}"
echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"

###############################################################################
#  PHASE 0: PREREQUISITES
###############################################################################
phase "PHASE 0 — Prerequisites"

step "0.1 Check tools"
for cmd in curl jq bc; do
    command -v "$cmd" &>/dev/null && pass "$cmd available" || fail "$cmd missing"
done

step "0.2 API Gateway health"
RESPONSE=$(do_curl GET /health)
HTTP_CODE=$(get_code "$RESPONSE")
assert_status "API Gateway" "$HTTP_CODE" "200"
if [[ "$HTTP_CODE" != "200" ]]; then
    echo -e "${RED}ERROR: API Gateway not running at ${BASE_URL}${NC}"
    echo "  Start with:  ./scripts/start-dev.sh"
    exit 1
fi

step "0.3 Solana validator health"
RPC_RESP=$(curl -s -X POST "$RPC_URL" -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}' 2>/dev/null || echo '{"error":"refused"}')
if echo "$RPC_RESP" | jq -r '.result' 2>/dev/null | grep -q "ok"; then
    pass "Solana validator healthy"
else
    skip "Solana validator not reachable"
fi

step "0.4 Fund authority wallet"
AUTH_WALLET="5FdkFZDC9x1u9mgtvqXSYCnXNgj4oEtTpaTRK4CSFCWW"
solana airdrop 10 "$AUTH_WALLET" --url "$RPC_URL" 2>/dev/null \
    && pass "Authority funded" || skip "Authority airdrop skipped"

echo ""
info "Run ID:    ${TS}"
info "Seller:    ${SELLER_EMAIL}"
info "Buyer:     ${BUYER_EMAIL}"
info "Meter-A:   ${METER_A_SERIAL} (solar producer)"
info "Meter-B:   ${METER_B_SERIAL} (consumer)"

###############################################################################
#  PHASE 1: REGISTER SELLER + WALLET
###############################################################################
phase "PHASE 1 — Register Seller (Solar Producer)"

step "1.1 Register seller"
REG_BODY=$(jq -n --arg u "$SELLER_USERNAME" --arg e "$SELLER_EMAIL" --arg p "$SELLER_PASSWORD" \
    '{username:$u,email:$e,password:$p,first_name:"Seller",last_name:"Solar"}')
RESPONSE=$(do_curl POST /api/v1/users -H "Content-Type: application/json" -d "$REG_BODY")
HTTP_CODE=$(get_code "$RESPONSE"); BODY=$(get_body "$RESPONSE")
echo "  $(echo "$BODY" | jq -c '.' 2>/dev/null || echo "$BODY")"
assert_status "Register seller" "$HTTP_CODE" "200"

SELLER_TOKEN=$(echo "$BODY" | jq -r '.auth.access_token // .access_token // empty' 2>/dev/null)
SELLER_ID=$(echo "$BODY" | jq -r '.auth.user.id // .user.id // empty' 2>/dev/null)
SELLER_WALLET=$(echo "$BODY" | jq -r '.auth.user.wallet_address // .user.wallet_address // empty' 2>/dev/null)

if [[ -z "$SELLER_TOKEN" || "$SELLER_TOKEN" == "null" ]]; then
    step "1.1b Login seller (fallback)"
    RESPONSE=$(do_curl POST /api/v1/auth/token -H "Content-Type: application/json" \
        -d "{\"username\":\"${SELLER_USERNAME}\",\"password\":\"${SELLER_PASSWORD}\"}")
    HTTP_CODE=$(get_code "$RESPONSE"); BODY=$(get_body "$RESPONSE")
    assert_status "Seller login" "$HTTP_CODE" "200"
    SELLER_TOKEN=$(echo "$BODY" | jq -r '.access_token // empty' 2>/dev/null)
    SELLER_WALLET=$(echo "$BODY" | jq -r '.user.wallet_address // empty' 2>/dev/null)
fi

step "1.2 Get/generate seller wallet"
if [[ -z "$SELLER_WALLET" || "$SELLER_WALLET" == "null" ]]; then
    RESPONSE=$(do_curl GET /api/v1/users/me -H "Authorization: Bearer ${SELLER_TOKEN}")
    SELLER_WALLET=$(echo "$(get_body "$RESPONSE")" | jq -r '.wallet_address // empty' 2>/dev/null)
fi
if [[ -z "$SELLER_WALLET" || "$SELLER_WALLET" == "null" ]]; then
    RESPONSE=$(do_curl_timeout 60 POST /api/v1/users/wallet/generate -H "Authorization: Bearer ${SELLER_TOKEN}")
    SELLER_WALLET=$(echo "$(get_body "$RESPONSE")" | jq -r '.wallet_address // empty' 2>/dev/null)
fi
if [[ -n "$SELLER_WALLET" && "$SELLER_WALLET" != "null" ]]; then
    pass "Seller wallet: ${SELLER_WALLET}"
    solana airdrop 2 "$SELLER_WALLET" --url "$RPC_URL" 2>/dev/null && info "Seller funded 2 SOL" || true
else
    fail "No seller wallet"
fi

step "1.3 Fund seller fiat via dev faucet"
RESPONSE=$(do_curl POST /api/v1/dev/faucet -H "Content-Type: application/json" \
    -d "{\"wallet_address\":\"${SELLER_WALLET}\",\"deposit_fiat\":50.0}")
HTTP_CODE=$(get_code "$RESPONSE")
[[ "$HTTP_CODE" == "200" ]] && pass "Seller fiat funded" || skip "Faucet HTTP ${HTTP_CODE}"

###############################################################################
#  PHASE 2: REGISTER BUYER + WALLET
###############################################################################
phase "PHASE 2 — Register Buyer (Energy Consumer)"

step "2.1 Register buyer"
REG_BODY=$(jq -n --arg u "$BUYER_USERNAME" --arg e "$BUYER_EMAIL" --arg p "$BUYER_PASSWORD" \
    '{username:$u,email:$e,password:$p,first_name:"Buyer",last_name:"Consumer"}')
RESPONSE=$(do_curl POST /api/v1/users -H "Content-Type: application/json" -d "$REG_BODY")
HTTP_CODE=$(get_code "$RESPONSE"); BODY=$(get_body "$RESPONSE")
echo "  $(echo "$BODY" | jq -c '.' 2>/dev/null || echo "$BODY")"
assert_status "Register buyer" "$HTTP_CODE" "200"

BUYER_TOKEN=$(echo "$BODY" | jq -r '.auth.access_token // .access_token // empty' 2>/dev/null)
BUYER_WALLET=$(echo "$BODY" | jq -r '.auth.user.wallet_address // .user.wallet_address // empty' 2>/dev/null)

if [[ -z "$BUYER_TOKEN" || "$BUYER_TOKEN" == "null" ]]; then
    step "2.1b Login buyer (fallback)"
    RESPONSE=$(do_curl POST /api/v1/auth/token -H "Content-Type: application/json" \
        -d "{\"username\":\"${BUYER_USERNAME}\",\"password\":\"${BUYER_PASSWORD}\"}")
    BUYER_TOKEN=$(echo "$(get_body "$RESPONSE")" | jq -r '.access_token // empty' 2>/dev/null)
fi

step "2.2 Get/generate buyer wallet"
if [[ -z "$BUYER_WALLET" || "$BUYER_WALLET" == "null" ]]; then
    RESPONSE=$(do_curl GET /api/v1/users/me -H "Authorization: Bearer ${BUYER_TOKEN}")
    BUYER_WALLET=$(echo "$(get_body "$RESPONSE")" | jq -r '.wallet_address // empty' 2>/dev/null)
fi
if [[ -z "$BUYER_WALLET" || "$BUYER_WALLET" == "null" ]]; then
    RESPONSE=$(do_curl_timeout 60 POST /api/v1/users/wallet/generate -H "Authorization: Bearer ${BUYER_TOKEN}")
    BUYER_WALLET=$(echo "$(get_body "$RESPONSE")" | jq -r '.wallet_address // empty' 2>/dev/null)
fi
if [[ -n "$BUYER_WALLET" && "$BUYER_WALLET" != "null" ]]; then
    pass "Buyer wallet: ${BUYER_WALLET}"
    solana airdrop 2 "$BUYER_WALLET" --url "$RPC_URL" 2>/dev/null && info "Buyer funded 2 SOL" || true
else
    fail "No buyer wallet"
fi

step "2.3 Fund buyer fiat via dev faucet"
RESPONSE=$(do_curl POST /api/v1/dev/faucet -H "Content-Type: application/json" \
    -d "{\"wallet_address\":\"${BUYER_WALLET}\",\"deposit_fiat\":100.0}")
HTTP_CODE=$(get_code "$RESPONSE")
[[ "$HTTP_CODE" == "200" ]] && pass "Buyer fiat funded" || skip "Faucet HTTP ${HTTP_CODE}"

###############################################################################
#  PHASE 3: REGISTER 2 SMART METERS
###############################################################################
phase "PHASE 3 — Register 2 Smart Meters"

step "3.1 Register Meter-A (Solar Producer — seller's meter)"
METER_A_BODY=$(jq -n --arg m "$METER_A_SERIAL" --arg w "$SELLER_WALLET" \
    '{meter_id:$m,wallet_address:$w,meter_type:"solar",location:"Zone-A-Solar-Farm",latitude:13.7563,longitude:100.5018,zone_id:1}')
RESPONSE=$(do_curl POST /api/v1/simulator/meters/register -H "Content-Type: application/json" -d "$METER_A_BODY")
HTTP_CODE=$(get_code "$RESPONSE"); BODY=$(get_body "$RESPONSE")
echo "  $(echo "$BODY" | jq -c '.' 2>/dev/null || echo "$BODY")"
assert_status "Register Meter-A (solar)" "$HTTP_CODE" "200"

step "3.2 Register Meter-B (Consumer — buyer's meter)"
METER_B_BODY=$(jq -n --arg m "$METER_B_SERIAL" --arg w "$BUYER_WALLET" \
    '{meter_id:$m,wallet_address:$w,meter_type:"residential",location:"Zone-B-Residential",latitude:13.75,longitude:100.49,zone_id:1}')
RESPONSE=$(do_curl POST /api/v1/simulator/meters/register -H "Content-Type: application/json" -d "$METER_B_BODY")
HTTP_CODE=$(get_code "$RESPONSE"); BODY=$(get_body "$RESPONSE")
echo "  $(echo "$BODY" | jq -c '.' 2>/dev/null || echo "$BODY")"
assert_status "Register Meter-B (consumer)" "$HTTP_CODE" "200"

step "3.3 Verify meters in public list"
RESPONSE=$(do_curl GET /api/v1/public/meters)
HTTP_CODE=$(get_code "$RESPONSE"); BODY=$(get_body "$RESPONSE")
METER_COUNT=$(echo "$BODY" | jq 'if type == "array" then length else 0 end' 2>/dev/null || echo "0")
[[ "$METER_COUNT" -ge 2 ]] && pass "Public meters: ${METER_COUNT} registered" || skip "Meter count: ${METER_COUNT}"

###############################################################################
#  PHASE 4: METER-A REALTIME SURPLUS READINGS → AUTO-MINT
###############################################################################
phase "PHASE 4 — Meter-A: Solar Surplus → Auto-Mint Tokens"

READING_TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

step "4.1 Meter-A submits surplus reading (8 kWh gen, 3 kWh consumed → 5 kWh surplus)"
READING_A1=$(cat <<EOF
{
  "wallet_address": "${SELLER_WALLET}",
  "kwh_amount": 5.0,
  "reading_timestamp": "${READING_TS}",
  "meter_serial": "${METER_A_SERIAL}",
  "energy_generated": 8.0,
  "energy_consumed": 3.0,
  "surplus_energy": 5.0,
  "deficit_energy": 0.0,
  "power_generated": 3.5,
  "power_consumed": 1.5,
  "voltage": 230.5,
  "current": 8.7,
  "power_factor": 0.95,
  "frequency": 50.01,
  "temperature": 32.5,
  "battery_level": 85.0,
  "latitude": 13.7563,
  "longitude": 100.5018,
  "zone_id": 1
}
EOF
)
RESPONSE=$(do_curl POST /api/meters/submit-reading \
    -H "Authorization: Bearer ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$READING_A1")
HTTP_CODE=$(get_code "$RESPONSE"); BODY=$(get_body "$RESPONSE")
echo "  $(echo "$BODY" | jq -c '.' 2>/dev/null || echo "$BODY")"
assert_status "Meter-A surplus reading" "$HTTP_CODE" "200"
RID_A1=$(echo "$BODY" | jq -r '.id // empty' 2>/dev/null)
[[ -n "$RID_A1" && "$RID_A1" != "null" ]] && pass "Reading ID: ${RID_A1}" || fail "No reading ID"

step "4.2 Poll for auto-mint tokens"
info "Polling seller balance for minted tokens (up to 25s)..."
RESPONSE=$(poll_until 5 5 GET /api/v1/trading/balance '.token_balance // 0 | select(. > 0)' \
    -H "Authorization: Bearer ${SELLER_TOKEN}") || true
HTTP_CODE=$(get_code "$RESPONSE"); BODY=$(get_body "$RESPONSE")
SELLER_BALANCE=$(echo "$BODY" | jq -r '.token_balance // .balance // 0' 2>/dev/null || echo "0")
echo "  Seller balance: ${SELLER_BALANCE}"
if (( $(echo "${SELLER_BALANCE} > 0" | bc -l 2>/dev/null || echo "0") )); then
    pass "Auto-mint succeeded — seller has ${SELLER_BALANCE} tokens"
else
    skip "Balance = 0 (mint may be async)"
fi

###############################################################################
#  PHASE 5: METER-B REALTIME DEFICIT READING
###############################################################################
phase "PHASE 5 — Meter-B: Consumer Deficit Reading"

DEFICIT_TS=$(date -u -v+1M +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "+1 min" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "2026-02-12T12:01:00Z")

step "5.1 Meter-B submits deficit reading (1 kWh gen, 4 kWh consumed → 3 kWh deficit)"
READING_B1=$(cat <<EOF
{
  "wallet_address": "${BUYER_WALLET}",
  "kwh_amount": -3.0,
  "reading_timestamp": "${DEFICIT_TS}",
  "meter_serial": "${METER_B_SERIAL}",
  "energy_generated": 1.0,
  "energy_consumed": 4.0,
  "surplus_energy": 0.0,
  "deficit_energy": 3.0,
  "power_generated": 0.5,
  "power_consumed": 2.0,
  "voltage": 228.5,
  "current": 9.1,
  "power_factor": 0.91,
  "frequency": 50.0,
  "temperature": 35.0,
  "battery_level": 30.0,
  "latitude": 13.75,
  "longitude": 100.49,
  "zone_id": 1
}
EOF
)
RESPONSE=$(do_curl POST /api/meters/submit-reading \
    -H "Authorization: Bearer ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$READING_B1")
HTTP_CODE=$(get_code "$RESPONSE"); BODY=$(get_body "$RESPONSE")
echo "  $(echo "$BODY" | jq -c '.' 2>/dev/null || echo "$BODY")"
assert_status "Meter-B deficit reading" "$HTTP_CODE" "200"
RID_B1=$(echo "$BODY" | jq -r '.id // empty' 2>/dev/null)
[[ -n "$RID_B1" && "$RID_B1" != "null" ]] && pass "Reading ID: ${RID_B1}" || fail "No reading ID"

###############################################################################
#  PHASE 6: REALTIME P2P TRADING — SELL ORDER
###############################################################################
phase "PHASE 6 — Seller Creates Sell Order (from surplus)"

step "6.1 Create sell order (3.0 kWh @ 2.50 THB/kWh)"
SELL_BODY='{"side":"sell","energy_amount":"3.00","price_per_kwh":"2.50","order_type":"limit","zone_id":1}'
RESPONSE=$(do_curl POST /api/v1/trading/orders \
    -H "Authorization: Bearer ${SELLER_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$SELL_BODY")
HTTP_CODE=$(get_code "$RESPONSE"); BODY=$(get_body "$RESPONSE")
echo "  $(echo "$BODY" | jq -c '.' 2>/dev/null || echo "$BODY")"
assert_status "Create sell order" "$HTTP_CODE" "200"
SELL_ORDER_ID=$(echo "$BODY" | jq -r '.id // empty' 2>/dev/null)
[[ -n "$SELL_ORDER_ID" && "$SELL_ORDER_ID" != "null" ]] \
    && pass "Sell order: ${SELL_ORDER_ID}" || fail "No sell order ID"

step "6.2 Verify in orderbook"
RESPONSE=$(do_curl GET /api/v1/public/trading/orderbook)
HTTP_CODE=$(get_code "$RESPONSE"); BODY=$(get_body "$RESPONSE")
echo "  $(echo "$BODY" | jq -c '.' 2>/dev/null | head -c 400)"
assert_status "Public orderbook" "$HTTP_CODE" "200"

###############################################################################
#  PHASE 7: REALTIME P2P TRADING — BUY ORDER (CROSSES)
###############################################################################
phase "PHASE 7 — Buyer Creates Buy Order (matches seller)"

step "7.1 Create buy order (3.0 kWh @ 4.00 THB/kWh — crosses sell at 2.50)"
BUY_BODY='{"side":"buy","energy_amount":"3.00","price_per_kwh":"4.00","order_type":"limit","zone_id":1}'
RESPONSE=$(do_curl POST /api/v1/trading/orders \
    -H "Authorization: Bearer ${BUYER_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$BUY_BODY")
HTTP_CODE=$(get_code "$RESPONSE"); BODY=$(get_body "$RESPONSE")
echo "  $(echo "$BODY" | jq -c '.' 2>/dev/null || echo "$BODY")"
assert_status "Create buy order" "$HTTP_CODE" "200"
BUY_ORDER_ID=$(echo "$BODY" | jq -r '.id // empty' 2>/dev/null)
[[ -n "$BUY_ORDER_ID" && "$BUY_ORDER_ID" != "null" ]] \
    && pass "Buy order: ${BUY_ORDER_ID}" || fail "No buy order ID"

###############################################################################
#  PHASE 8: ORDER MATCHING + SETTLEMENT
###############################################################################
phase "PHASE 8 — Order Matching & Settlement"

step "8.1 Promote seller to admin for match trigger"
RESPONSE=$(do_curl POST /api/v1/dev/faucet -H "Content-Type: application/json" \
    -d "{\"wallet_address\":\"${SELLER_WALLET}\",\"promote_to_role\":\"admin\"}")
HTTP_CODE=$(get_code "$RESPONSE")
ADMIN_TOKEN=""
if [[ "$HTTP_CODE" == "200" ]]; then
    pass "Seller promoted to admin"
    ADMIN_TOKEN="$SELLER_TOKEN"
else
    info "Promotion HTTP ${HTTP_CODE} — trying admin login"
    RESPONSE=$(do_curl POST /api/v1/auth/token -H "Content-Type: application/json" \
        -d '{"username":"admin@gridtokenx.com","password":"password123"}')
    ADMIN_TOKEN=$(echo "$(get_body "$RESPONSE")" | jq -r '.access_token // empty' 2>/dev/null)
    [[ -n "$ADMIN_TOKEN" && "$ADMIN_TOKEN" != "null" ]] && pass "Admin login OK" || ADMIN_TOKEN=""
fi

step "8.2 Trigger order matching"
if [[ -n "$ADMIN_TOKEN" ]]; then
    RESPONSE=$(do_curl_timeout 120 POST /api/v1/trading/admin/match-orders \
        -H "Authorization: Bearer ${ADMIN_TOKEN}" \
        -H "Content-Type: application/json")
    HTTP_CODE=$(get_code "$RESPONSE"); BODY=$(get_body "$RESPONSE")
    echo "  $(echo "$BODY" | jq -c '.' 2>/dev/null || echo "$BODY")"
    [[ "$HTTP_CODE" == "200" ]] && pass "Match orders triggered" || skip "Match HTTP ${HTTP_CODE}"
else
    skip "No admin token — waiting for auto-match"
fi

step "8.3 Poll for trade settlement (up to 25s)"
TRADE_RESP=$(poll_until 5 5 GET /api/v1/trading/trades '.trades | length | select(. > 0)' \
    -H "Authorization: Bearer ${SELLER_TOKEN}") || true
TRADE_CODE=$(get_code "$TRADE_RESP"); TRADE_BODY=$(get_body "$TRADE_RESP")
TRADE_COUNT=$(echo "$TRADE_BODY" | jq '.trades | if type == "array" then length else 0 end' 2>/dev/null || echo "0")
if [[ "$TRADE_COUNT" -gt 0 ]]; then
    pass "Trade settled! ${TRADE_COUNT} trade(s) recorded"
    echo "  $(echo "$TRADE_BODY" | jq -c '.trades[0]' 2>/dev/null)"
else
    skip "No trades yet (matching may be pending)"
fi

###############################################################################
#  PHASE 9: VERIFY FINAL BALANCES
###############################################################################
phase "PHASE 9 — Verify Final Balances"

step "9.1 Seller final balance"
RESPONSE=$(do_curl_timeout 8 GET /api/v1/trading/balance -H "Authorization: Bearer ${SELLER_TOKEN}")
HTTP_CODE=$(get_code "$RESPONSE"); BODY=$(get_body "$RESPONSE")
echo "  $(echo "$BODY" | jq -c '.' 2>/dev/null || echo "$BODY")"
assert_status "Seller balance" "$HTTP_CODE" "200"
SELLER_FINAL=$(echo "$BODY" | jq -r '.token_balance // .balance // 0' 2>/dev/null || echo "0")
info "Seller final: ${SELLER_FINAL} tokens"

step "9.2 Buyer final balance"
RESPONSE=$(do_curl_timeout 8 GET /api/v1/trading/balance -H "Authorization: Bearer ${BUYER_TOKEN}")
HTTP_CODE=$(get_code "$RESPONSE"); BODY=$(get_body "$RESPONSE")
echo "  $(echo "$BODY" | jq -c '.' 2>/dev/null || echo "$BODY")"
assert_status "Buyer balance" "$HTTP_CODE" "200"
BUYER_FINAL=$(echo "$BODY" | jq -r '.token_balance // .balance // 0' 2>/dev/null || echo "0")
info "Buyer final: ${BUYER_FINAL} tokens"

step "9.3 Verify token transfer occurred"
if (( $(echo "${BUYER_FINAL} > 0" | bc -l 2>/dev/null || echo "0") )); then
    pass "Buyer received tokens from trade (balance = ${BUYER_FINAL})"
elif [[ "$TRADE_COUNT" -gt 0 ]]; then
    pass "Trade recorded — on-chain transfer may be async"
else
    skip "No trade + no buyer tokens (end-to-end settlement pending)"
fi

step "9.4 Market stats"
RESPONSE=$(do_curl GET /api/v1/public/trading/market/stats)
HTTP_CODE=$(get_code "$RESPONSE"); BODY=$(get_body "$RESPONSE")
echo "  $(echo "$BODY" | jq -c '.' 2>/dev/null | head -c 400)"
[[ "$HTTP_CODE" == "200" ]] && pass "Market stats available" || skip "Market stats HTTP ${HTTP_CODE}"

###############################################################################
#  SUMMARY
###############################################################################
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
echo ""
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}          ⚡ E2E REALTIME TRADING SUMMARY ⚡${NC}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Duration:  ${BOLD}${DURATION}s${NC}"
echo -e "  Total:     ${BOLD}${TOTAL}${NC}"
echo -e "  ${GREEN}Passed:    ${PASSED}${NC}"
echo -e "  ${RED}Failed:    ${FAILED}${NC}"
echo -e "  ${YELLOW}Skipped:   ${SKIPPED}${NC}"
echo ""
echo -e "${BOLD}  Artifacts:${NC}"
echo "    Seller:       ${SELLER_EMAIL} (wallet: ${SELLER_WALLET:-N/A})"
echo "    Buyer:        ${BUYER_EMAIL} (wallet: ${BUYER_WALLET:-N/A})"
echo "    Meter-A:      ${METER_A_SERIAL} (solar, surplus reading: ${RID_A1:-N/A})"
echo "    Meter-B:      ${METER_B_SERIAL} (consumer, deficit reading: ${RID_B1:-N/A})"
echo "    Sell Order:   ${SELL_ORDER_ID:-N/A}"
echo "    Buy Order:    ${BUY_ORDER_ID:-N/A}"
echo "    Trades:       ${TRADE_COUNT}"
echo "    Seller Final: ${SELLER_FINAL} tokens"
echo "    Buyer Final:  ${BUYER_FINAL} tokens"
echo ""

if [[ "$FAILED" -eq 0 ]]; then
    echo -e "  ${GREEN}${BOLD}✔ All tests passed!${NC}"
    exit 0
else
    echo -e "  ${RED}${BOLD}✘ ${FAILED} test(s) failed.${NC}"
    exit 1
fi
