import requests
import subprocess
import time
import json
import sys
import random
import string

# Configuration
API_URL = "http://localhost:4000"
SIMULATOR_URL = "http://localhost:8080"

# Colors for output
GREEN = "\033[92m"
RED = "\033[91m"
RESET = "\033[0m"
BOLD = "\033[1m"

def log(message, success=None):
    if success is True:
        print(f"{GREEN}✓ {message}{RESET}")
    elif success is False:
        print(f"{RED}✗ {message}{RESET}")
    else:
        print(f"{BOLD}→ {message}{RESET}")

def generate_random_string(length=8):
    return ''.join(random.choices(string.ascii_lowercase + string.digits, k=length))

class GridTokenXTest:
    def __init__(self):
        self.buyer_token = None
        self.seller_token = None
        self.buyer_id = None
        self.seller_id = None
        self.buyer_meter = f"METER-BUY-{generate_random_string(5)}"
        self.seller_meter = f"METER-SELL-{generate_random_string(5)}"

    def register_user(self, prefix, role):
        username = f"{prefix}_{generate_random_string()}"
        email = f"{username}@test.com"
        password = "GridTokenX@2026!Strong"
        
        payload = {
            "username": username,
            "email": email,
            "password": password,
            "first_name": prefix.capitalize(),
            "last_name": "Tester",
            "role": role # Note: Role might be ignored by registration and set via default, but good to send
        }
        
        log(f"Registering {role}: {username}...", None)
        res = requests.post(f"{API_URL}/api/v1/users", json=payload)
        
        # API bug: Returns 200 even on failure sometimes?
        # Check logical success via auth token presence
        is_success = False
        try:
             data = res.json()
             if 'auth' in data and data['auth']:
                 is_success = True
        except:
             pass

        if (res.status_code != 200 and res.status_code != 201) or not is_success:
            log(f"Registration failed: {res.text}", False)
            return None, None
            
        log(f"Registered {username}", True)
        
        # Check if token is in registration response
        try:
            print(f"DEBUG: Reg response text: {res.text}")
            reg_data = res.json()
            print(f"DEBUG: Reg response json: {json.dumps(reg_data)}") 
            if 'auth' in reg_data and reg_data['auth']:
                token = reg_data['auth']['access_token']
                user_id = reg_data['auth']['user']['id']
                log(f"Got token from registration. ID: {user_id}", True)
                return token, user_id
        except Exception as e:
            print(f"DEBUG: Token extraction failed: {e}")
            pass
        
        # Login to get token (fallback)
        log(f"Logging in as {username} (using email {email})...", None)
        res = requests.post(f"{API_URL}/api/v1/auth/token", json={
            "username": email, # Use email as username for login
            "password": password
        })
        
        if res.status_code != 200:
            log(f"Login failed: {res.text}", False)
            sys.exit(1)
            
        data = res.json()
        token = data['auth']['access_token']
        user_id = data['user']['id']
        
        log(f"Logged in. ID: {user_id}", True)
        return token, user_id

    def register_meter(self, token, serial):
        log(f"Registering meter {serial}...", None)
        headers = {"Authorization": f"Bearer {token}"}
        payload = {
            "serial_number": serial,
            "meter_type": "Smart_Gen_v1",
            "location": "Test Lab",
            "latitude": 13.7563,
            "longitude": 100.5018
        }
        
        res = requests.post(f"{API_URL}/api/v1/meters", json=payload, headers=headers)
        
        if res.status_code not in [200, 201]:
             log(f"Meter registration failed: {res.text}", False)
             # Proceeding anyway as it might be already registered from previous run
        else:
            log(f"Meter registered", True)
            
    def submit_reading(self, token, serial, kwh):
        log(f"Submitting reading for {serial}: {kwh} kWh...", None)
        headers = {"Authorization": f"Bearer {token}"}
        payload = {
            "meter_serial": serial,
            "kwh": kwh
        }
        
        # Try batch endpoint or individual
        # Based on routes, it seems we have POST /api/v1/meters/readings or /batch/readings
        # Let's try the individual one or wait... actually minting usually happens on reading.
        # Checking routes.rs: .route("/{serial}/readings", post(create_reading))
        
        res = requests.post(f"{API_URL}/api/v1/meters/{serial}/readings", json=payload, headers=headers)
        
        if res.status_code not in [200, 201]:
            log(f"Reading submission failed: {res.text}", False)
        else:
            log(f"Reading submitted. Tokens should be minted.", True)

    def create_order(self, token, side, amount, price):
        log(f"Creating {side} order: {amount} kWh @ {price} THB...", None)
        headers = {"Authorization": f"Bearer {token}"}
        payload = {
            "side": side,
            "energy_amount": amount,
            "price_per_kwh": price,
            "order_type": "limit"
        }
        
        res = requests.post(f"{API_URL}/api/v1/trading/orders", json=payload, headers=headers)
        
        if res.status_code not in [200, 201]:
            log(f"Order creation failed: {res.text}", False)
            return None
        
        order_data = res.json()
        log(f"Order created: {order_data.get('id', 'Unknown')}", True)
        return order_data.get('id')

    def check_order_status(self, token, order_id):
        log(f"Checking status for order {order_id}...", None)
        headers = {"Authorization": f"Bearer {token}"}
        
        # We might need to list orders to find it, or get by ID if endpoint exists
        # Routes: GET /api/v1/trading/orders (list)
        res = requests.get(f"{API_URL}/api/v1/trading/orders", headers=headers)
        
        if res.status_code != 200:
             log(f"Failed to fetch orders: {res.text}", False)
             return None
             
        orders = res.json()
        if isinstance(orders, dict) and 'data' in orders: # Handle potential paginated response
            orders = orders['data']
            
        for order in orders:
            if order['id'] == order_id:
                return order['status']
        
        return "NOT_FOUND"

    def link_wallet(self, token, prefix):
        # Generate a new valid Solana address using solana-keygen
        # ensuring uniqueness for each test run
        try:
            result = subprocess.run(
                ["solana-keygen", "new", "--no-outfile", "--no-bip39-passphrase"],
                capture_output=True,
                text=True,
                check=True
            )
            # Parse output for "pubkey: <address>"
            for line in result.stdout.splitlines():
                if "pubkey:" in line:
                    wallet = line.split("pubkey:")[1].strip()
                    break
        except Exception as e:
            log(f"Failed to generate wallet: {e}. Using fallback.", False)
            wallet = generate_random_string(44) # Fallback (will fail validation but keeping flow)

        log(f"Linking wallet {wallet} for {prefix}...", None)
        
        headers = {"Authorization": f"Bearer {token}"}
        payload = {
            "wallet_address": wallet,
            "label": "Primary Wallet",
            "is_primary": True
        }
        
        res = requests.post(f"{API_URL}/api/v1/user-wallets", json=payload, headers=headers)
        
        if res.status_code != 200:
            log(f"Link wallet failed: {res.text}", False)
            return None
            
        log(f"Wallet linked: {wallet}", True)
        return wallet

    def fund_user(self, wallet, amount):
        log(f"Funding user wallet {wallet} with {amount} THB...", None)
        payload = {
            "wallet_address": wallet,
            "deposit_fiat": amount
        }
        
        # Call dev faucet
        res = requests.post(f"{API_URL}/api/v1/dev/faucet", json=payload)
        
        if res.status_code != 200:
             log(f"Funding failed: {res.status_code} {res.text}", False)
        else:
             log(f"Funding successful", True)

    def run(self):
        log("=== Starting GridTokenX E2E Test ===")
        
        # 1. Register Users
        self.seller_token, self.seller_id = self.register_user("seller", "prosumer")
        self.buyer_token, self.buyer_id = self.register_user("buyer", "consumer")
        
        if not self.seller_token or not self.buyer_token:
            log("User registration failed. Aborting.", False)
            return

        # 1.5 Link Wallets & Fund Buyer
        seller_wallet = self.link_wallet(self.seller_token, "seller")
        buyer_wallet = self.link_wallet(self.buyer_token, "buyer")
        
        if buyer_wallet:
            self.fund_user(buyer_wallet, 1000.0)
        
        # 2. Register Meters
        self.register_meter(self.seller_token, self.seller_meter)
        self.register_meter(self.buyer_token, self.buyer_meter)
        
        # 3. Mint Tokens (Seller needs energy tokens to sell)
        # Verify the meter first to allow minting? (Assuming auto-verification dev mode or skip)
        # Attempt to submit reading
        self.submit_reading(self.seller_token, self.seller_meter, 50.0)
        
        # Give it a moment for async processing (if any)
        time.sleep(2)
        
        # 4. Place Orders
        # Seller sells 10 units at 5.0
        ask_id = self.create_order(self.seller_token, "sell", 10.0, 5.0)
        
        # Buyer buys 10 units at 5.0
        bid_id = self.create_order(self.buyer_token, "buy", 10.0, 5.0)
        
        if not ask_id or not bid_id:
            log("Failed to create orders. Aborting.", False)
            return

        # 5. Wait for Matching
        log("Waiting for matching engine...", None)
        for i in range(10):
            time.sleep(2)
            ask_status = self.check_order_status(self.seller_token, ask_id)
            bid_status = self.check_order_status(self.buyer_token, bid_id)
            
            log(f"Attempt {i+1}: Ask={ask_status}, Bid={bid_status}")
            
            # Matched statuses: "filled", "partially_filled", or "settled"
            # Note: "filled" means order executed.
            valid_stats = ["filled", "settled"]
            if ask_status in valid_stats and bid_status in valid_stats:
                log("Orders Matched and Filled!", True)
                break
            
            if i == 9:
                log("Timeout waiting for order fill.", False)

        log("=== E2E Test Complete ===")

if __name__ == "__main__":
    test = GridTokenXTest()
    test.run()
