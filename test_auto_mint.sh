#!/bin/bash
echo "🚀 Testing Automatic Token Minting"
echo "Starting balance:"
spl-token balance Gy6hmzLZT2QU54vQ94XrvxRWxsafTacFpVc4bJUXmnyY --owner 2Xyfzwzq7vATKYYT2SPjERVbQESq8F4PXo1WNmo1Ba29
echo ""
echo "Sending 3 meter readings (20 seconds apart)..."
echo "---"

for i in {1..3}; do
  KWH=$(echo "scale=2; 8 + $RANDOM % 10" | bc)
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  echo ""
  echo "📊 Reading #$i: $KWH kWh at $(date +%H:%M:%S)"
  
  RESPONSE=$(curl -s -X POST http://localhost:4000/api/meters/submit-reading \
    -H "Content-Type: application/json" \
    -d "{\"wallet_address\":\"2Xyfzwzq7vATKYYT2SPjERVbQESq8F4PXo1WNmo1Ba29\",\"kwh_amount\":\"$KWH\",\"reading_timestamp\":\"$TIMESTAMP\"}")
  
  MINTED=$(echo $RESPONSE | jq -r '.minted')
  TX=$(echo $RESPONSE | jq -r '.mint_tx_signature' | cut -c1-20)
  
  if [ "$MINTED" = "true" ]; then
    echo "   ✅ Minted! TX: ${TX}..."
  else
    echo "   ❌ Failed: $(echo $RESPONSE | jq -r '.message' | head -c 80)"
  fi
  
  if [ $i -lt 3 ]; then
    echo "   ⏳ Waiting 20 seconds..."
    sleep 20
  fi
done

echo ""
echo "---"
echo "Final balance:"
spl-token balance Gy6hmzLZT2QU54vQ94XrvxRWxsafTacFpVc4bJUXmnyY --owner 2Xyfzwzq7vATKYYT2SPjERVbQESq8F4PXo1WNmo1Ba29
