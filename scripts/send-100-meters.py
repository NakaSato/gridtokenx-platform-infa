#!/usr/bin/env python3
"""
Send 100 meter readings to Solana blockchain via GridTokenX API Gateway.

This script demonstrates bulk meter reading submission:
1. Register 100 meters using the simulator endpoint
2. Send readings for all meters
3. Track success/failure rates

Usage:
    python3 scripts/send-100-meters.py
"""

import json
import time
import uuid
import urllib.request
import urllib.error
from datetime import datetime, timezone
from concurrent.futures import ThreadPoolExecutor, as_completed
import random

# Configuration
API_GATEWAY_URL = "http://localhost:4000"
API_KEY = "engineering-department-api-key-2025"
NUM_METERS = 100

# Headers
HEADERS = {
    "Content-Type": "application/json",
    "X-API-Key": API_KEY,
}

# Statistics
stats = {
    "registered": 0,
    "failed_register": 0,
    "readings_submitted": 0,
    "readings_failed": 0,
}


def make_request(url, payload, headers, method="POST", timeout=30):
    """Helper to make HTTP requests using urllib."""
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            return response.status, json.loads(response.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        try:
            error_body = json.loads(e.read().decode('utf-8'))
        except:
            error_body = {"error": str(e)}
        return e.code, error_body
    except urllib.error.URLError as e:
        return None, {"error": str(e.reason)}
    except Exception as e:
        return None, {"error": str(e)}


def register_meter(meter_serial, wallet_address, zone_id):
    """Register a meter using the simulator endpoint."""
    url = f"{API_GATEWAY_URL}/api/v1/simulator/meters/register"
    payload = {
        "meter_id": meter_serial,
        "wallet_address": wallet_address,
        "meter_type": random.choice(["solar_prosumer", "consumer", "hybrid", "battery"]),
        "location": f"Test Location Zone {zone_id}",
        "latitude": 13.7563 + random.uniform(-0.1, 0.1),  # Bangkok area
        "longitude": 100.5018 + random.uniform(-0.1, 0.1),
        "zone_id": zone_id,
    }
    
    status, result = make_request(url, payload, HEADERS)
    
    if status in (200, 201):
        stats["registered"] += 1
        return True
    else:
        stats["failed_register"] += 1
        print(f"      Register error {status}: {json.dumps(result, indent=2)[:100]}")
        return False


def send_reading(meter_serial, wallet_address, kwh, energy_generated, energy_consumed):
    """Send a meter reading."""
    url = f"{API_GATEWAY_URL}/api/meters/submit-reading"
    payload = {
        "meter_serial": meter_serial,
        "wallet_address": wallet_address,
        "kwh_amount": float(kwh),
        "energy_generated": float(energy_generated),
        "energy_consumed": float(energy_consumed),
        "reading_timestamp": datetime.now(timezone.utc).isoformat(),
    }
    
    status, result = make_request(url, payload, HEADERS, timeout=10)
    
    if status in (200, 201):
        stats["readings_submitted"] += 1
        return True, result
    else:
        stats["readings_failed"] += 1
        return False, result


def generate_meter_data(meter_type):
    """Generate realistic meter data based on type."""
    if meter_type == "solar_prosumer":
        # Generates more than consumes
        generated = random.uniform(5.0, 15.0)
        consumed = random.uniform(1.0, 5.0)
        kwh = generated - consumed
    elif meter_type == "consumer":
        # Only consumes
        generated = 0.0
        consumed = random.uniform(3.0, 10.0)
        kwh = -consumed
    elif meter_type == "hybrid":
        # Balanced
        generated = random.uniform(3.0, 8.0)
        consumed = random.uniform(2.0, 6.0)
        kwh = generated - consumed
    else:  # battery
        # Can charge or discharge
        if random.random() > 0.5:
            generated = random.uniform(2.0, 5.0)
            consumed = 0.0
            kwh = generated
        else:
            generated = 0.0
            consumed = random.uniform(2.0, 5.0)
            kwh = -consumed
    
    return round(kwh, 2), round(generated, 2), round(consumed, 2)


def register_and_send_meter(meter_idx):
    """Register a meter and send one reading."""
    meter_serial = f"METER-{meter_idx:04d}-{uuid.uuid4().hex[:8].upper()}"
    
    # Generate a valid-looking Solana public key (32 bytes Base58)
    # Using a deterministic but unique key for each meter index
    import hashlib
    seed = f"meter-wallet-seed-{meter_idx}".encode()
    hash_bytes = hashlib.sha256(seed).digest()
    
    # Simple Base58 encoding helper (or just use a known valid prefix)
    # For now, let's just use a real-looking 44-character string
    # We can use a few pre-recorded ones or just generate a reasonably valid one.
    # Since we don't have a bs58 lib here, we use a simple alphabetic mapping for the dev-test.
    # Actually, let's just use the 'METER' prefix + hex, which is NOT base58.
    # Let's use a 44 character string of valid Base58 chars.
    base58_chars = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    wallet_address = "".join(base58_chars[b % 58] for b in hash_bytes) + "xxxx" # 32 + 4 = 36 chars
    
    zone_id = (meter_idx % 10) + 1  # Zones 1-10
    meter_type = random.choice(["solar_prosumer", "consumer", "hybrid", "battery"])
    
    # Register meter
    registered = register_meter(meter_serial, wallet_address, zone_id)
    
    if not registered:
        return meter_idx, False, "Registration failed"
    
    # Generate and send reading
    kwh, generated, consumed = generate_meter_data(meter_type)
    success, result = send_reading(meter_serial, wallet_address, kwh, generated, consumed)
    
    return meter_idx, success, result


def main():
    """Main function to send 100 meter readings."""
    print("=" * 80)
    print("  GridTokenX - Send 100 Meter Readings to Solana Blockchain")
    print("=" * 80)
    print(f"\n🔗 API Gateway: {API_GATEWAY_URL}")
    print(f"📊 Number of Meters: {NUM_METERS}")
    print(f"🕐 Start Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    start_time = time.time()
    
    # Use thread pool for parallel execution
    print(f"\n🚀 Starting bulk registration and submission...")
    print(f"   Using ThreadPoolExecutor for parallel requests\n")
    
    results = []
    
    # Process in batches of 10 to avoid overwhelming the server
    batch_size = 10
    total_batches = NUM_METERS // batch_size
    
    with ThreadPoolExecutor(max_workers=5) as executor:
        for batch_num in range(total_batches):
            batch_start = batch_num * batch_size
            batch_end = batch_start + batch_size
            
            # Submit batch
            futures = [executor.submit(register_and_send_meter, i) 
                      for i in range(batch_start, batch_end)]
            
            # Collect results
            for future in as_completed(futures):
                meter_idx, success, result = future.result()
                results.append((meter_idx, success, result))
                
                status_icon = "✅" if success else "❌"
                print(f"   {status_icon} Meter {meter_idx:04d}: {'Success' if success else 'Failed'}")
            
            # Progress update
            completed = (batch_num + 1) * batch_size
            print(f"\n   📊 Progress: {completed}/{NUM_METERS} meters processed\n")
            
            # Small delay between batches
            if batch_num < total_batches - 1:
                time.sleep(0.5)
    
    elapsed_time = time.time() - start_time
    
    # Print summary
    print("\n" + "=" * 80)
    print("  Summary")
    print("=" * 80)
    print(f"\n📈 Registration Statistics:")
    print(f"   ✅ Successfully registered: {stats['registered']}/{NUM_METERS}")
    print(f"   ❌ Failed to register: {stats['failed_register']}/{NUM_METERS}")
    
    print(f"\n📊 Reading Submission Statistics:")
    print(f"   ✅ Successfully submitted: {stats['readings_submitted']}/{stats['registered']}")
    print(f"   ❌ Failed to submit: {stats['readings_failed']}/{stats['registered']}")
    
    success_rate = (stats['readings_submitted'] / NUM_METERS * 100) if NUM_METERS > 0 else 0
    
    print(f"\n🎯 Overall Success Rate: {success_rate:.1f}%")
    print(f"⏱️  Total Time: {elapsed_time:.2f} seconds")
    print(f"⚡ Throughput: {NUM_METERS / elapsed_time:.1f} meters/second")
    
    if stats['readings_submitted'] > 0:
        print(f"\n🎉 {stats['readings_submitted']} readings submitted to blockchain!")
        print(f"🔍 View transactions at: https://explorer.solana.com/txs?cluster=custom&customUrl=http://localhost:8899")
    
    print("\n" + "=" * 80)
    
    # Save results to file
    results_file = f"scripts/results-{int(time.time())}.json"
    with open(results_file, 'w') as f:
        json.dump({
            "timestamp": datetime.now().isoformat(),
            "total_meters": NUM_METERS,
            "statistics": stats,
            "success_rate": success_rate,
            "elapsed_time": elapsed_time,
            "throughput": NUM_METERS / elapsed_time,
        }, f, indent=2)
    
    print(f"\n💾 Results saved to: {results_file}")
    print("\n" + "=" * 80)


if __name__ == "__main__":
    main()
