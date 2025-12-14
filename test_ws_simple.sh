#!/bin/bash
# Simple WebSocket test using curl (HTTP upgrade)
echo "Testing WebSocket connection..."
timeout 30 curl -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: test" http://localhost:4000/ws 2>&1 | head -20 &
WS_PID=$!

sleep 3

# Send a test meter reading to trigger WebSocket events
echo ""
echo "Sending meter reading to trigger WebSocket events..."
curl -X POST http://localhost:4000/api/meters/submit-reading \
  -H "Content-Type: application/json" \
  -d '{"wallet_address":"2Xyfzwzq7vATKYYT2SPjERVbQESq8F4PXo1WNmo1Ba29","kwh_amount":"7.5","reading_timestamp":"2024-12-14T06:27:00Z"}' 2>&1 | jq -r '.minted, .mint_tx_signature' | head -2

sleep 2
kill $WS_PID 2>/dev/null
