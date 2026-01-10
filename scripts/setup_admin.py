import requests
import sys
import subprocess
import time
import json

API_URL = "http://localhost:4000"

def log(msg):
    print(f"-> {msg}")

def generate_solana_address():
    try:
        result = subprocess.run(
            ["solana-keygen", "new", "--no-outfile", "--no-bip39-passphrase"],
            capture_output=True,
            text=True,
            check=True
        )
        for line in result.stdout.splitlines():
            if "pubkey:" in line:
                return line.split("pubkey:")[1].strip()
    except Exception as e:
        log(f"Failed to generate wallet: {e}")
        sys.exit(1)

def run():
    log("=== Setting up Admin User ===")
    
    # 1. Register User
    username = f"admin_user_{int(time.time())}"
    email = f"{username}@gridtokenx.com"
    password = f"S{int(time.time())}x!#Complex"
    
    payload = {
        "username": username,
        "email": email,
        "password": password,
        "first_name": "Admin",
        "last_name": "User",
        "role": "user" # Register as normal user first
    }
    
    res = requests.post(f"{API_URL}/api/v1/users", json=payload)
    print(f"DEBUG: Reg Response: {res.status_code} {res.text}")
    if res.status_code not in [200, 201]:
        log(f"Registration failed: {res.text}")
        sys.exit(1)
        
    data = res.json()
    token = None
    if 'auth' in data and data['auth']:
        token = data['auth']['access_token']
    else:
        log("Registration success, logging in...")
        login_res = requests.post(f"{API_URL}/api/v1/auth/token", json={
            "username": email,
            "password": password
        })
        if login_res.status_code != 200:
            log(f"Login failed: {login_res.text}")
            sys.exit(1)
        token = login_res.json()['auth']['access_token']
        
    log(f"User registered: {username}")
    
    # 2. Link Wallet
    wallet = generate_solana_address()
    log(f"Generated wallet: {wallet}")
    
    headers = {"Authorization": f"Bearer {token}"}
    wallet_payload = {
        "wallet_address": wallet,
        "label": "Admin Wallet",
        "is_primary": True
    }
    
    res = requests.post(f"{API_URL}/api/v1/user-wallets", json=wallet_payload, headers=headers)
    if res.status_code != 200:
        log(f"Link wallet failed: {res.text}")
        sys.exit(1)
        
    log("Wallet linked.")
    
    # 3. Promote to Admin via Faucet
    faucet_payload = {
        "wallet_address": wallet,
        "promote_to_role": "admin"
    }
    
    res = requests.post(f"{API_URL}/api/v1/dev/faucet", json=faucet_payload)
    if res.status_code != 200:
        log(f"Promotion failed: {res.text}")
        sys.exit(1)
        
    log("User promoted to ADMIN.")
    
    # 3.5 Re-login to get new token with admin role
    log("Re-logging in to refresh token claims...")
    res = requests.post(f"{API_URL}/api/v1/auth/token", json={
        "username": email,
        "password": password
    })
    
    print(f"DEBUG: Login Response: {res.status_code} {res.text}")
    if res.status_code != 200:
        log(f"Re-login failed: {res.text}")
        sys.exit(1)
        
    token = res.json()['access_token']
    log("Got new admin token.")
    
    # 4. output token
    print("\nXXX ADMIN TOKEN XXX")
    print(token)
    print("XXX ADMIN TOKEN XXX\n")

if __name__ == "__main__":
    run()
