import csv
import uuid
import random
import os

# Configuration
COUNT = 1000
START_METER_ID = 20000
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
    
    # Open CSV for Simulator
    with open(OUTPUT_CSV, 'w', newline='') as csvfile:
        fieldnames = [
            'meter_id', 'meter_type', 'lat', 'lon', 'transformer_id', 
            'contract_capacity_kw', 'building_area', 'dist_to_transformer_m'
        ]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        
        for i in range(COUNT):
            meter_id = f"MEA-{START_METER_ID + i}"
            user_id = str(uuid.uuid4())
            wallet_addr = f"LOADTEST{uuid.uuid4().hex[:32]}"
            
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
                'email': f"loadtest_{i+1}@test.com",
                'wallet_address': wallet_addr,
                'role': 'prosumer' if is_prosumer else 'consumer'
            })
            
            meters.append({
                'id': str(uuid.uuid4()),
                'user_id': user_id,
                'serial_number': meter_id,
                'meter_type': meter_type,
                'location': f"{lat},{lon}"
            })

    print(f"Generated {OUTPUT_CSV}")

    # Generate SQL
    with open(OUTPUT_SQL, 'w') as sqlfile:
        sqlfile.write("-- Load Test Data Seeding\n")
        
        # Insert Users
        sqlfile.write("-- Users\n")
        for u in users:
            sqlfile.write(
                f"INSERT INTO users (id, email, wallet_address, role, created_at, updated_at) "
                f"VALUES ('{u['id']}', '{u['email']}', '{u['wallet_address']}', '{u['role']}', NOW(), NOW()) "
                f"ON CONFLICT (email) DO NOTHING;\n"
            )
            
        sqlfile.write("\n-- Meters\n")
        for m in meters:
            sqlfile.write(
                f"INSERT INTO meters (id, user_id, serial_number, meter_type, location, is_verified, created_at, updated_at) "
                f"VALUES ('{m['id']}', '{m['user_id']}', '{m['serial_number']}', '{m['meter_type']}', '{m['location']}', true, NOW(), NOW()) "
                f"ON CONFLICT (serial_number) DO NOTHING;\n"
            )
            
    print(f"Generated {OUTPUT_SQL}")

if __name__ == "__main__":
    main()
