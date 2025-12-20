import urllib.request
import json
import ssl

try:
    print("1. Getting Token...")
    url = "http://localhost:4000/api/v1/auth/token"
    data = json.dumps({"username": "meter_test_user", "password": "password123"}).encode('utf-8')
    headers = {"Content-Type": "application/json"}
    req = urllib.request.Request(url, data=data, headers=headers, method='POST')
    
    token = ""
    with urllib.request.urlopen(req) as f:
        resp = json.loads(f.read().decode('utf-8'))
        token = resp['access_token']
        print(f"Token obtained: {token[:10]}...")
        
    meter = "bb6052e6-f238-4790-8b02-e22421b9cc65"
    
    print("\n2. Verifying Meter...")
    v_url = f"http://localhost:4000/api/v1/meters/{meter}"
    v_data = json.dumps({"status": "verified"}).encode('utf-8')
    v_headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    v_req = urllib.request.Request(v_url, data=v_data, headers=v_headers, method='PATCH')
    try:
        with urllib.request.urlopen(v_req) as vf:
            print("Verify Response:", vf.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        print(f"Verify Failed: {e.code} {e.read().decode('utf-8')}")
        
    print("\n3. Testing Mint (+50)...")
    m_url = f"http://localhost:4000/api/v1/meters/{meter}/readings"
    m_data = json.dumps({"kwh": 50, "wallet_address": "11111111111111111111111111111111"}).encode('utf-8')
    m_req = urllib.request.Request(m_url, data=m_data, headers=v_headers, method='POST')
    try:
        with urllib.request.urlopen(m_req) as mf:
            print("Mint Response:", mf.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        print(f"Mint Failed: {e.code} {e.read().decode('utf-8')}")

    print("\n4. Testing Burn (-20)...")
    b_data = json.dumps({"kwh": -20, "wallet_address": "11111111111111111111111111111111"}).encode('utf-8')
    b_req = urllib.request.Request(m_url, data=b_data, headers=v_headers, method='POST')
    try:
        with urllib.request.urlopen(b_req) as bf:
            print("Burn Response:", bf.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        print(f"Burn Failed: {e.code} {e.read().decode('utf-8')}")

except Exception as e:
    print("Execution Error:", e)
