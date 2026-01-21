import csv
import uuid
import random
import bcrypt
import time
import os

# Configuration
COUNT = 1000
START_METER_ID = 20000

# Output files
OUTPUT_CSV = "load_test_meters.csv"
OUTPUT_SQL = "seed_1000_users.sql"

# MEA Bangkok simulation parameters
CENTER_LAT = 13.780157
CENTER_LON = 100.560237
RADIUS = 0.05  # degrees, approx 5km

def generate_random_location():
    lat = CENTER_LAT + random.uniform(-RADIUS, RADIUS)
    lon = CENTER_LON + random.uniform(-RADIUS, RADIUS)
    return lat, lon

def main():
    print(f"Generating data for {COUNT} users/meters...")
    
    users = []
    meters = []

    # 1. Create Demo User (for UI Login)
    print("Creating Demo User: demo@gridtokenx.com / password123")
    demo_email = "demo@gridtokenx.com"
    demo_uuid = str(uuid.uuid5(uuid.NAMESPACE_DNS, demo_email))
    demo_pw_hash = bcrypt.hashpw(b"password123", bcrypt.gensalt()).decode('utf-8')
    demo_meter_id = "MEA-DEMO-2026"
    demo_meter_uuid = str(uuid.uuid5(uuid.NAMESPACE_DNS, demo_meter_id))
    
    users.append({
        'id': demo_uuid,
        'email': demo_email,
        'username': "demo_user",
        'password_hash': demo_pw_hash,
        'wallet_address': "DEMO_WALLET_ADDR_SOLANA_DEVNET",
        'role': 'prosumer'
    })
    
    meters.append({
        'id': demo_meter_uuid,
        'user_id': demo_uuid,
        'serial_number': demo_meter_id,
        'meter_type': "Solar_Prosumer", # Demo user produces energy
        'location': f"{CENTER_LAT},{CENTER_LON}"
    })
    
    # Open CSV for Simulator
    with open(OUTPUT_CSV, 'w', newline='') as csvfile:
        fieldnames = [
            'meter_id', 'meter_type', 'lat', 'lon', 'transformer_id', 
            'contract_capacity_kw', 'building_area', 'dist_to_transformer_m'
        ]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        
        # Write Demo Meter to CSV
        writer.writerow({
            'meter_id': demo_meter_id,
            'meter_type': "15(45) A",
            'lat': CENTER_LAT,
            'lon': CENTER_LON,
            'transformer_id': 1,
            'contract_capacity_kw': 15.0,
            'building_area': 150.0,
            'dist_to_transformer_m': 100.0
        })
        
        for i in range(COUNT):
            meter_id = f"MEA-{START_METER_ID + i}"
            email = f"loadtest_{i+1}@test.com"
            
            # Deterministic UUIDs based on unique keys
            user_id = str(uuid.uuid5(uuid.NAMESPACE_DNS, email))
            # For meter, we use serial number as seed
            meter_uuid = str(uuid.uuid5(uuid.NAMESPACE_DNS, meter_id))
            
            wallet_addr = f"LOADTEST{uuid.uuid4().hex[:32]}" # Wallet can be random or deterministic, random is fine for now as it's not a unique key constraint usually, but let's make it deterministic too for safety
            wallet_addr = f"LOADTEST{uuid.uuid5(uuid.NAMESPACE_DNS, email).hex[:32]}"

            lat, lon = generate_random_location()
            
            # Attributes
            is_prosumer = random.random() < 0.3
            meter_type = "Solar_Prosumer" if is_prosumer else "Grid_Consumer"
            csv_meter_type = "15(45) A" # Default mapped in seed logic
            
            if is_prosumer:
                csv_meter_type = "15(45) A"
            else:
                csv_meter_type = "5(15) A"
                
            transformer_id = random.randint(0, 50)
            
            # Write to CSV row (Simulator format)
            row = {
                'meter_id': meter_id,
                'meter_type': csv_meter_type, # seed_mea_data uses this column to map
                'lat': lat,
                'lon': lon,
                'transformer_id': transformer_id,
                'contract_capacity_kw': 15.0,
                'building_area': 150.0,
                'dist_to_transformer_m': random.uniform(10, 500)
            }
            writer.writerow(row)
            
            # SQL Data
            users.append({
                'id': user_id,
                'email': email,
                'username': f"loadtest_{i+1}",
                'password_hash': "loadtest_password_hash",
                'wallet_address': wallet_addr,
                'role': 'prosumer' if is_prosumer else 'consumer'
            })
            
            meters.append({
                'id': meter_uuid,
                'user_id': user_id,
                'serial_number': meter_id,
                'meter_type': meter_type,
                'location': f"{lat},{lon}"
            })

    print(f"Generated {OUTPUT_CSV}")

    # Generate SQL
    with open(OUTPUT_SQL, 'w') as sqlfile:
        sqlfile.write("-- Load Test Data Seeding\n")
        sqlfile.write("-- Clean up previous test data to avoid Foreign Key conflicts\n")
        sqlfile.write("DELETE FROM p2p_orders WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'loadtest_%' OR email = 'demo@gridtokenx.com');\n")
        sqlfile.write("DELETE FROM swap_transactions WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'loadtest_%' OR email = 'demo@gridtokenx.com');\n")
        sqlfile.write("DELETE FROM carbon_transactions WHERE from_user_id IN (SELECT id FROM users WHERE email LIKE 'loadtest_%' OR email = 'demo@gridtokenx.com') OR to_user_id IN (SELECT id FROM users WHERE email LIKE 'loadtest_%' OR email = 'demo@gridtokenx.com');\n")
        sqlfile.write("DELETE FROM zone_rates WHERE created_by IN (SELECT id FROM users WHERE email LIKE 'loadtest_%' OR email = 'demo@gridtokenx.com');\n")
        sqlfile.write(f"DELETE FROM meters WHERE (serial_number >= 'MEA-{START_METER_ID}' AND serial_number < 'MEA-{START_METER_ID + COUNT}') OR serial_number = 'MEA-DEMO-2026';\n")
        sqlfile.write("DELETE FROM users WHERE email LIKE 'loadtest_%' OR email = 'demo@gridtokenx.com';\n\n")
        
        # Insert Users
        sqlfile.write("-- Users\n")
        for u in users:
            sqlfile.write(
                f"INSERT INTO users (id, email, username, password_hash, wallet_address, role, balance, created_at, updated_at) "
                f"VALUES ('{u['id']}', '{u['email']}', '{u['username']}', '{u['password_hash']}', '{u['wallet_address']}', '{u['role']}', 1000.0, NOW(), NOW()) "
                f"ON CONFLICT (email) DO UPDATE SET balance = 1000.0;\n"
            )
            
        sqlfile.write("\n-- Meters\n")
        for m in meters:
            sqlfile.write(
                f"INSERT INTO meters (id, user_id, serial_number, meter_type, location, is_verified, created_at, updated_at) "
                f"VALUES ('{m['id']}', '{m['user_id']}', '{m['serial_number']}', '{m['meter_type']}', '{m['location']}', true, NOW(), NOW()) "
                f"ON CONFLICT (serial_number) DO UPDATE SET user_id = EXCLUDED.user_id;\n"
            )
            
    print(f"Generated {OUTPUT_SQL}")

if __name__ == "__main__":
    main()
