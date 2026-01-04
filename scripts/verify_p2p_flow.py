
import requests
import time
import hmac
import hashlib
import json
import sys

# Configuration
API_URL = "http://localhost:4000/api/v1"
SECRET_KEY = "test_secret_key"
HEADERS = {"Content-Type": "application/json"}

def print_step(msg):
    print(f"\n[STEP] {msg}")

def register_user(email, password, role="user"):
    print(f"Registering user {email}...")
    payload = {
        "email": email,
        "username": email,
        "password": password,
        "first_name": "Test",
        "last_name": "User",
        "role": role
    }
    # Register endpoint is /users
    resp = requests.post(f"{API_URL}/users", json=payload)
    if resp.status_code == 200:
        data = resp.json()
        if "Registration failed" in data.get("message", ""):
            print(f"Registration failed (Logic): {data['message']}")
            sys.exit(1)
            
        print(f"User {email} registered successfully.")
        
        # Verify user to generate wallet (Test Mode) -> GET /auth/verify?token=verify_{username}
        # Note: Username is same as email in our script
        verify_token = f"verify_{email}"
        print(f"Verifying user {email} with token {verify_token}...")
        v_resp = requests.get(f"{API_URL}/auth/verify", params={"token": verify_token})
        if v_resp.status_code == 200:
            print(f"User {email} verified and wallet generated.")
        else:
            print(f"Verification failed: {v_resp.text}")
            # Non-fatal? No, fatal for P2P.
            sys.exit(1)

        # If role is admin, we must manually promote via DB since API hardcodes 'user'
        if role == "admin":
            promote_to_admin(email)

        return login_user(email, password)
    elif resp.status_code == 409:
        print(f"User {email} already exists, logging in...")
        # If existing admin, might need promotion too? 
        if role == "admin":
             promote_to_admin(email)
        return login_user(email, password)
    else:
        print(f"Failed to register user: {resp.text}")
        sys.exit(1)

def promote_to_admin(email):
    import subprocess
    print(f"Promoting {email} to admin via Docker...")
    cmd = [
        "docker", "exec", "gridtokenx-postgres", 
        "psql", "-U", "gridtokenx_user", "-d", "gridtokenx", 
        "-c", f"UPDATE users SET role = 'admin' WHERE email = '{email}';"
    ]
    try:
        subprocess.run(cmd, check=True, capture_output=True)
        print("Promotion successful.")
    except subprocess.CalledProcessError as e:
        print(f"Promotion failed: {e.stderr.decode()}")
        sys.exit(1)

def login_user(email, password):
    # Login endpoint is /auth/token
    resp = requests.post(f"{API_URL}/auth/token", json={"email": email, "username": email, "password": password})
    if resp.status_code == 200:
        return resp.json()["access_token"]
    else:
        print(f"Failed to login: {resp.text}")
        sys.exit(1)

def get_wallet(token):
    # User profile is at /users/me
    resp = requests.get(f"{API_URL}/users/me", headers={"Authorization": f"Bearer {token}"})
    if resp.status_code == 200:
        return resp.json()["wallet_address"]
    return None

def mint_tokens(token, amount):
    print(f"Minting {amount} tokens...")
    wallet = get_wallet(token)
    if not wallet:
        print("User has no wallet address, cannot mint!")
        sys.exit(1)
    
    # Use dev faucet: POST /dev/faucet
    payload = {
        "wallet_address": wallet,
        "mint_tokens_kwh": amount
    }
    # No auth header needed for public faucet, but doesn't hurt.
    resp = requests.post(f"{API_URL}/dev/faucet", json=payload)
    if resp.status_code == 200:
        print("Mint successful.")
        sig = resp.json().get('token_tx_signature', 'unknown')
        print(f"Tx Signature: {sig}")
        
        # Verify balance explicitly using CLI
        # We need the Mint Address. It's likely in the env or we can hardcode the one from earlier logs/config
        # Default dev mint: Geq98m3Vw63AqrMEVoZsiW5DbNkScteZAdWDmm95ykYF
        # But let's try to fetch it or just check 'any' token account?
        # Better: run `spl-token accounts` for the wallet
        check_token_balance(wallet)
    else:
        print(f"Mint failed: {resp.text}")
        sys.exit(1)

def check_token_balance(wallet):
    import subprocess
    print(f"Checking token balance for {wallet}...")
    try:
        # Check all token accounts for this wallet
        cmd = ["spl-token", "accounts", "--owner", wallet, "--verbose", "--program-2022", "--url", "http://localhost:8899"]
        output = subprocess.check_output(cmd, stderr=subprocess.STDOUT).decode()
        print("Token Accounts:")
        print(output)
    except subprocess.CalledProcessError as e:
        print(f"Failed to check balance: {e.output.decode()}")

def create_order(token, side, amount, price, zone_id=1):
    print(f"Creating {side.upper()} order: {amount} kWh @ {price} GRX...")
    
    timestamp = int(time.time() * 1000)
    
    # Construct message for HMAC
    # Format: {side}:{amount}:{price}:{timestamp}
    # side must be lowercase
    side_lower = side.lower()
    
    # Amount and price formatting:
    # Rust Debug/Display for Decimal might produce "10.5" or "10.50".
    # The backend code: `amount_str = payload.energy_amount.to_string();`
    # Let's assume standard formatting.
    
    message = f"{side_lower}:{amount}:{price}:{timestamp}"
    signature = hmac.new(
        SECRET_KEY.encode('utf-8'),
        message.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()
    
    payload = {
        "side": side_lower,
        "order_type": "limit",
        "energy_amount": str(amount),
        "price_per_kwh": str(price),
        "zone_id": zone_id,
        "timestamp": timestamp,
        "signature": signature
    }
    
    resp = requests.post(f"{API_URL}/trading/orders", json=payload, headers={"Authorization": f"Bearer {token}"})
    if resp.status_code == 200:
        print(f"Order created. ID: {resp.json().get('id')}")
        return resp.json().get('id')
    else:
        print(f"Order creation failed: {resp.text}")
        sys.exit(1)

def trigger_matching(admin_token):
    print("Triggering order matching...")
    # Endpoint is /trading/admin/match-orders
    resp = requests.post(f"{API_URL}/trading/admin/match-orders", headers={"Authorization": f"Bearer {admin_token}"})
    if resp.status_code == 200:
        print("Matching triggered successfully.")
        data = resp.json()
        print(f"Matched Orders: {data.get('matched_orders')}")
        return data.get('matched_orders')
    else:
        print(f"Trigger matching failed: {resp.text}")
        sys.exit(1)

def check_order_status(token, order_id):
    # Fetch all orders and find ours
    resp = requests.get(f"{API_URL}/trading/orders", headers={"Authorization": f"Bearer {token}"})
    if resp.status_code == 200:
        data = resp.json()
        orders = data.get('data', data) if isinstance(data, dict) else data
        for o in orders:
            if o['id'] == order_id:
                return o['status']
    return "unknown"

def main():
    try:
        ts = int(time.time())
        # 1. Setup Admin (for matching)
        admin_token = register_user(f"admin_{ts}@test.com", "P2P_Trading_Test!987", role="admin")
        
        # 2. Setup Seller
        seller_token = register_user(f"seller_{ts}@test.com", "P2P_Trading_Test!987", role="prosumer")
        
        # 3. Setup Buyer
        buyer_token = register_user(f"buyer_{ts}@test.com", "P2P_Trading_Test!987", role="consumer")
        
        # 4. Fund Seller
        # Only admin can mint? Or users can mint for dev?
        # The endpoint /tokens/mint usually checks user authority. 
        # In this dev env, let's try minting as the seller themselves.
        # If that fails, we use admin to mint TO seller (if endpoint supports it).
        # Looking at `services/blockchain/service.rs`: `mint_tokens_direct` uses `get_authority_keypair()` (Backend Admin Wallet) 
        # to mint to `user_wallet`. It doesn't seem to restrict who calls it in `handlers/tokens.rs` (need to verify, but usually open in dev).
        # Let's try minting AS the seller.
        mint_tokens(seller_token, 100.0)
        
        # Funding Buyer with some SOL (via airdrop/mint) might be needed for rent?
        # The backend handles "lazy wallet generation" and "airdrop" automatically when `create_order` calls `execute_on_chain_order_creation`.
        # So we just need to ensure they have enough GRX tokens for the trade (Seller needs GRX, Buyer needs SOL which is auto-airdropped).
        
        # Start WebSocket listener in the background
        print("Starting WebSocket listener...")
        import subprocess
        ws_proc = subprocess.Popen(
            [sys.executable.replace("python3", "python"), "scripts/listen_ws.py", buyer_token],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # 5. Create Orders
        sell_amount = 10.0
        buy_amount = 10.0
        price = 0.5
        
        sell_id = create_order(seller_token, "sell", sell_amount, price)
        buy_id = create_order(buyer_token, "buy", buy_amount, price)
        
        print("Waiting for orders to settle (simulating network delay)...")
        time.sleep(2)
        
        # 6. Trigger Matching (Must be Admin)
        matches = trigger_matching(admin_token)
        
        if matches == 0:
            print("WARNING: No matches reported. Logic might check epochs or exact matching.")
        
        # 7. Verify Status
        # Wait a moment for async settlement if any
        time.sleep(2)
        
        seller_status = check_order_status(seller_token, sell_id)
        buyer_status = check_order_status(buyer_token, buy_id)
        
        print(f"Seller Order Status: {seller_status}")
        print(f"Buyer Order Status: {buyer_status}")
        
        if seller_status == "filled" and buyer_status == "filled":
            print("\nSUCCESS: P2P Trade Verified!")
        else:
            print("\nFAILURE: Orders did not fill completely.")
            sys.exit(1)

        # Check WS listener output
        print("Checking WebSocket listener results...")
        try:
            stdout, stderr = ws_proc.communicate(timeout=5)
            print("Listener STDOUT:\n", stdout)
            if "✅ SUCCESS" in stdout:
                print("WebSocket broadcast verified successfully!")
            else:
                print("WebSocket broadcast NOT found in listener output.")
        except subprocess.TimeoutExpired:
            ws_proc.kill()
            stdout, stderr = ws_proc.communicate()
            print("Listener timed out. STDOUT:\n", stdout)

    except Exception as e:
        print(f"An error occurred: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
