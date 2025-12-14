#!/usr/bin/env python3
"""
Simple test script to verify automatic token minting.
Sends meter readings to the Gateway every 20 seconds.
"""

import requests
import time
import random
from datetime import datetime, timezone

# Configuration
GATEWAY_URL = "http://localhost:4000/api/meters/submit-reading"
WALLET_ADDRESS = "2Xyfzwzq7vATKYYT2SPjERVbQESq8F4PXo1WNmo1Ba29"
INTERVAL = 20  # seconds

def generate_reading():
    """Generate a simulated meter reading"""
    # Simulate solar generation (varies by time of day)
    hour = datetime.now().hour
    if 6 <= hour <= 18:
        # Daytime - generate solar energy
        kwh = round(random.uniform(5.0, 15.0), 2)
    else:
        # Nighttime - no generation
        kwh = 0.0
    
    return {
        "wallet_address": WALLET_ADDRESS,
        "kwh_amount": str(kwh),
        "reading_timestamp": datetime.now(timezone.utc).isoformat(),
        "meter_signature": "auto_test_signature",
        "meter_serial": "auto_test_meter_001"
    }

def send_reading(reading):
    """Send reading to Gateway"""
    try:
        response = requests.post(GATEWAY_URL, json=reading, timeout=30)
        if response.status_code in (200, 201):
            data = response.json()
            print(f"✅ Reading sent: {reading['kwh_amount']} kWh")
            if data.get('minted'):
                print(f"   🎉 Minted! TX: {data.get('mint_tx_signature', 'N/A')[:20]}...")
            else:
                print(f"   ⚠️  Not minted: {data.get('message', 'Unknown')}")
            return True
        else:
            print(f"❌ Failed: {response.status_code} - {response.text[:100]}")
            return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def main():
    print("🚀 Starting automatic meter reading simulator")
    print(f"📍 Gateway: {GATEWAY_URL}")
    print(f"💰 Wallet: {WALLET_ADDRESS}")
    print(f"⏱️  Interval: {INTERVAL} seconds")
    print(f"🌞 Daytime hours (6-18): Will generate 5-15 kWh")
    print(f"🌙 Nighttime hours: Will generate 0 kWh (skipped)")
    print("-" * 60)
    
    reading_count = 0
    try:
        while True:
            reading_count += 1
            print(f"\n📊 Reading #{reading_count} at {datetime.now().strftime('%H:%M:%S')}")
            
            reading = generate_reading()
            
            # Skip if no generation
            if float(reading['kwh_amount']) <= 0:
                print(f"   ⏭️  Skipping (no generation)")
            else:
                send_reading(reading)
            
            print(f"   ⏳ Waiting {INTERVAL} seconds...")
            time.sleep(INTERVAL)
            
    except KeyboardInterrupt:
        print(f"\n\n🛑 Stopped after {reading_count} readings")

if __name__ == "__main__":
    main()
