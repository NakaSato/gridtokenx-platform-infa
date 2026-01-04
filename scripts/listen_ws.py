import asyncio
import websockets
import json
import sys

async def listen_trades(ws_url):
    print(f"Connecting to {ws_url}...")
    try:
        async with websockets.connect(ws_url) as websocket:
            print("Connected! Waiting for messages...")
            while True:
                message = await websocket.recv()
                data = json.loads(message)
                print(f"Received: {json.dumps(data, indent=2)}")
                if data.get("type") == "trade_executed":
                    print("✅ SUCCESS: Found trade_executed event!")
                    return
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python scripts/listen_ws.py <token>")
        sys.exit(1)
    
    token = sys.argv[1]
    ws_url = f"ws://localhost:4000/ws?token={token}"
    asyncio.run(listen_trades(ws_url))
