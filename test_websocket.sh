#!/bin/bash
# WebSocket Test Client
# Connects to Gateway WebSocket and listens for real-time events

echo "🔌 Connecting to Gateway WebSocket..."
echo "📡 Listening for real-time token minting events..."
echo "---"

# Use websocat if available, otherwise use a simple Node.js script
if command -v websocat &> /dev/null; then
    websocat ws://localhost:4000/ws
else
    # Fallback: create a simple Node.js WebSocket client
    node -e "
const WebSocket = require('ws');
const ws = new WebSocket('ws://localhost:4000/ws');

ws.on('open', () => {
    console.log('✅ Connected to Gateway WebSocket');
});

ws.on('message', (data) => {
    try {
        const event = JSON.parse(data);
        console.log('\\n📨 Event received:');
        console.log(JSON.stringify(event, null, 2));
    } catch (e) {
        console.log('Raw message:', data.toString());
    }
});

ws.on('error', (error) => {
    console.error('❌ WebSocket error:', error.message);
});

ws.on('close', () => {
    console.log('🔌 Disconnected from Gateway');
    process.exit(0);
});
    " 2>/dev/null || echo "⚠️  Neither websocat nor Node.js with ws module found. Please install one of them."
fi
