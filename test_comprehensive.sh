#!/bin/bash
echo "🧪 GridTokenX Comprehensive Testing Suite"
echo "=========================================="
echo ""

WALLET="2Xyfzwzq7vATKYYT2SPjERVbQESq8F4PXo1WNmo1Ba29"
MINT="Gy6hmzLZT2QU54vQ94XrvxRWxsafTacFpVc4bJUXmnyY"

echo "📊 Test 1: Multiple Meter Readings"
echo "-----------------------------------"
INITIAL_BALANCE=$(spl-token balance $MINT --owner $WALLET 2>&1)
echo "Initial balance: $INITIAL_BALANCE"

for i in {1..3}; do
  KWH=$(echo "scale=2; 5 + $i * 2" | bc)
  echo "  Reading $i: ${KWH} kWh"
  RESPONSE=$(curl -s -X POST http://localhost:4000/api/meters/submit-reading \
    -H "Content-Type: application/json" \
    -d "{\"wallet_address\":\"$WALLET\",\"kwh_amount\":\"$KWH\",\"reading_timestamp\":\"2024-12-14T07:20:00Z\"}")
  
  MINTED=$(echo $RESPONSE | jq -r '.minted')
  if [ "$MINTED" = "true" ]; then
    echo "    ✅ Minted successfully"
  else
    echo "    ❌ Failed: $(echo $RESPONSE | jq -r '.message')"
  fi
  sleep 2
done

FINAL_BALANCE=$(spl-token balance $MINT --owner $WALLET 2>&1)
echo "Final balance: $FINAL_BALANCE"
echo ""

echo "✅ Test 1 Complete"
echo ""
