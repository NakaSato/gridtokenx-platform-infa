# User Registration Workflow

**Version:** 1.0  
**Last Updated:** March 16, 2026  
**Authors:** GridTokenX Engineering Team

---

## Overview

This document describes the complete user registration workflow for the GridTokenX P2P energy trading platform, from initial sign-up through meter registration and blockchain onboarding.

### Key Features

| Feature | Implementation | Benefit |
|---------|----------------|---------|
| **Self-Service Registration** | Public API endpoint | No admin intervention required |
| **Auto-Generated Wallet** | Solana keypair created during registration | Users don't need crypto knowledge |
| **Encrypted Key Storage** | AES-256 encryption with secret sharding | Bank-level security |
| **Email Verification** | Token-based verification with expiry | Prevents spam, ensures valid email |
| **Initial Airdrop** | 20 GRX tokens + 1 SOL automatically | Users can start immediately |
| **O(1) Registration** | Async email & airdrop (non-blocking) | ~200-500ms response time |

---

## Complete Registration Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    USER REGISTRATION WORKFLOW                            │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│  PHASE 1: USER REGISTRATION (Public API)                                 │
│  Endpoint: POST /api/v1/users                                            │
│  Location: gridtokenx-api/src/api/handlers/auth_hdl/registration.rs│
└──────────────────────────────────────────────────────────────────────────┘

    ┌──────────────────────────────────────────────────────────────────┐
    │  1.1 User Submits Registration Form                              │
    │      Frontend: Trading UI / Portal                               │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Request Body:
       │ {
       │   "username": "john_doe",
       │   "email": "john@example.com",
       │   "password": "SecureP@ssw0rd!",
       │   "first_name": "John",
       │   "last_name": "Doe"
       │ }
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.2 Hash Password with Argon2id                                 │
    │      File: registration.rs → PasswordService::hash_password()    │
    │      Latency: ~50-100ms (spawn_blocking)                         │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Uses tokio::spawn_blocking to avoid blocking async runtime
       │ Password hashed with Argon2id (OWASP recommended)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.3 Generate Solana Keypair                                     │
    │      File: registration.rs → WalletService::create_keypair()     │
    │      Latency: < 10ms                                             │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Creates Ed25519 keypair:
       │ - Public Key: 9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusV (wallet address)
       │ - Private Key: 64 bytes (encrypted before storage)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.4 Encrypt Private Key (Secret Sharding)                       │
    │      File: registration.rs → WalletService::encrypt_private_key()│
    │      Latency: ~10-20ms (spawn_blocking)                          │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Encryption Process:
       │ 1. Derive encryption key from master_secret + user_password
       │ 2. Generate random salt (16 bytes) and IV (12 bytes)
       │ 3. Encrypt private key using AES-256-GCM
       │ 4. Store: encrypted_key + salt + iv (private key never stored raw)
       │
       │ Security:
       │ - Master secret stored in environment variable
       │ - User password not stored (used only for derivation)
       │ - Requires both master secret AND user password to decrypt
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.5 Generate Email Verification Token                           │
    │      File: registration.rs → Uuid::new_v4()                      │
    │      Latency: < 1ms                                              │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Creates:
       │ - verification_token: UUID v4 (e.g., "550e8400-e29b-41d4-a716-446655440000")
       │ - verification_expires_at: Current time + 24 hours (configurable)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.6 Insert User into PostgreSQL                                 │
    │      File: registration.rs → sqlx::query!(INSERT INTO users)     │
    │      Latency: 5-20ms                                             │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ SQL Insert:
       │ INSERT INTO users (
       │   id, username, email, password_hash, role, first_name, last_name,
       │   is_active, email_verified, blockchain_registered, balance,
       │   wallet_address, encrypted_private_key, wallet_salt, encryption_iv,
       │   email_verification_token, email_verification_sent_at, 
       │   email_verification_expires_at, created_at, updated_at
       │ ) VALUES (
       │   $1, $2, $3, $4, 'user', $5, $6, true, false, false, 20,  -- 20 GRX airdrop
       │   $7, $8, $9, $10, $11, NOW(), $12, NOW(), NOW()
       │ )
       │
       │ Initial State:
       │ - email_verified: false (pending email verification)
       │ - blockchain_registered: false (will be updated on first tx)
       │ - balance: 20 GRX (initial airdrop)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.7 Spawn SOL Airdrop Background Task                           │
    │      File: registration.rs → tokio::spawn(async move { ... })    │
    │      Latency: < 1ms (non-blocking)                               │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Background Process:
       │ 1. Request 1.0 SOL from local faucet (dev) or configured faucet
       │ 2. Send to user's wallet address
       │ 3. Wait for confirmation (async)
       │
       │ Note: In production, this may be skipped or use testnet faucet
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.8 Generate JWT Token                                          │
    │      File: registration.rs → jwt_service.encode_token()          │
    │      Latency: < 5ms                                              │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ JWT Claims:
       │ {
       │   "sub": "user-uuid",
       │   "username": "john_doe",
       │   "role": "user",
       │   "exp": 1710686400  // 24 hours from now
       │ }
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.9 Spawn Email Sending Task                                    │
    │      File: registration.rs → tokio::spawn(async move { ... })    │
    │      Latency: < 1ms (non-blocking)                               │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Background Process:
       │ 1. Call notification_service.send_verification_email()
       │ 2. Email contains verification link:
       │    https://gridtokenx.orbstack.local/verify-email?token=<verification_token>
       │ 3. Log success/failure (doesn't affect registration)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.10 Return Registration Response                               │
    │      File: registration.rs → Ok(Json(RegistrationResponse))      │
    │      Total Latency: ~200-500ms                                   │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ HTTP 200 Response:
       │ {
       │   "message": "Registration successful! 🎉 We've added 20 GRX to your account. Please check your email to verify your account.",
       │   "email_verification_sent": true,
       │   "auth": {
       │     "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
       │     "expires_in": 86400,
       │     "user": {
       │       "id": "user-uuid",
       │       "username": "john_doe",
       │       "email": "john@example.com",
       │       "role": "user",
       │       "first_name": "John",
       │       "last_name": "Doe",
       │       "wallet_address": "9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusV",
       │       "balance": 20.0,  // GRX tokens
       │       "locked_amount": 0.0,
       │       "locked_energy": 0.0
       │     }
       │   }
       │ }
       │
       │ ✅ USER REGISTERED - Can login immediately
       │ ⚠️ Email verification still required for full access (meter registration, trading)
       │
       ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  PHASE 2: EMAIL VERIFICATION                                             │
│  Endpoint: GET /api/v1/auth/verify-email                                 │
│  Location: gridtokenx-api/src/api/handlers/auth_hdl/login.rs      │
└──────────────────────────────────────────────────────────────────────────┘

    ┌──────────────────────────────────────────────────────────────────┐
    │  2.1 User Clicks Verification Link in Email                      │
    │      URL: https://gridtokenx.orbstack.local/verify-email?token=<token>      │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Frontend extracts token from URL and calls:
       │ GET /api/v1/auth/verify-email?token=<verification_token>
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  2.2 Validate Verification Token                                 │
    │      File: login.rs → verify_email()                             │
    │      Latency: 5-20ms                                             │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ SQL Query:
       │ SELECT id, email_verification_expires_at 
       │ FROM users 
       │ WHERE email_verification_token = $1
       │
       │ Validation:
       │ ✓ Token exists in database
       │ ✓ Token not expired (expires_at > now)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  2.3 Update User Record                                          │
    │      File: login.rs → sqlx::query!(UPDATE users)                 │
    │      Latency: 5-20ms                                             │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ SQL Update:
       │ UPDATE users
       │ SET email_verified = true,
       │     email_verification_token = NULL,
       │     updated_at = NOW()
       │ WHERE id = $1
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  2.4 Return Success Response                                     │
    │      File: login.rs → Ok(Json(VerifyEmailResponse))              │
    │      Total Latency: ~30-50ms                                     │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ HTTP 200 Response:
       │ {
       │   "success": true,
       │   "message": "Email verified successfully! You can now register meters and trade energy.",
       │   "wallet_address": "9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusV"
       │ }
       │
       │ ✅ EMAIL VERIFIED - Full platform access granted
       │
       ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  PHASE 3: METER REGISTRATION (Authenticated User)                        │
│  Endpoint: POST /api/v1/meters                                           │
│  Location: gridtokenx-api/src/api/handlers/auth_hdl/meters/registration.rs │
└──────────────────────────────────────────────────────────────────────────┘

    ┌──────────────────────────────────────────────────────────────────┐
    │  3.1 User Submits Meter Registration Form                        │
    │      Frontend: Trading UI / Dashboard                            │
    │      Auth: Bearer Token (JWT)                                    │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Request Headers:
       │ Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
       │
       │ Request Body:
       │ {
       │   "serial_number": "15165c03-bfaa-4ce9-b3a9-ef09090c18f0",
       │   "meter_type": "residential",
       │   "location": "123 Solar Street, Bangkok",
       │   "latitude": 13.7563,
       │   "longitude": 100.5018,
       │   "zone_id": 1
       │ }
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  3.2 Validate JWT Token                                          │
    │      File: auth.rs middleware → validate_token()                 │
    │      Latency: < 5ms                                              │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Extracts user_id (sub claim) from JWT
       │ user_id: "user-uuid"
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  3.3 Check User Eligibility                                      │
    │      File: registration.rs → sqlx::query!()                      │
    │      Latency: 5-20ms                                             │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ SQL Query:
       │ SELECT email_verified, wallet_address 
       │ FROM users 
       │ WHERE id = $1
       │
       │ Validation:
       │ ✓ email_verified = true (must verify email first)
       │ ✓ wallet_address IS NOT NULL (auto-created during registration)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  3.4 Check Meter Serial Uniqueness                               │
    │      File: registration.rs → sqlx::query!()                      │
    │      Latency: 5-20ms                                             │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ SQL Query:
       │ SELECT id FROM meters 
       │ WHERE serial_number = $1
       │
       │ If exists → Return 400 Error: "Meter already registered"
       │ If not exists → Continue
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  3.5 (Optional) Lookup Meter in Simulator                        │
    │      File: registration.rs → SimulatorClient::lookup_meter()     │
    │      Latency: 50-200ms (HTTP call to simulator)                  │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ HTTP GET: http://localhost:8082/api/meters/{serial_number}
       │
       │ If found in simulator:
       │ - Auto-populate location, coordinates, zone_id
       │ - Verify meter exists in simulation database
       │
       │ If not found:
       │ - Allow manual registration (for real meters)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  3.6 Insert Meter into Database                                  │
    │      File: registration.rs → sqlx::query!(INSERT INTO meters)    │
    │      Latency: 5-20ms                                             │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ SQL Insert:
       │ INSERT INTO meters (
       │   id, user_id, serial_number, meter_type, location,
       │   latitude, longitude, zone_id, is_verified,
       │   created_at, updated_at
       │ ) VALUES (
       │   $1, $2, $3, $4, $5, $6, $7, $8, false, NOW(), NOW()
       │ )
       │
       │ Initial State:
       │ - is_verified: false (pending admin or on-chain verification)
       │ - user_id: linked to registered user
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  3.7 Register Meter On-Chain (Registry Program)                  │
    │      File: registration.rs → blockchain_service.register_meter_on_chain() │
    │      Latency: ~100-300ms (send transaction, no wait)             │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Solana Transaction:
       │ ┌───────────────────────────────────────────────────────────┐
       │ │ Program: Registry (FmvDiFUWPrwXsqo7z7XnVniKbZDcz32U5HSDVwPug89c) │
       │ │ Instruction: register_meter                               │
       │ │                                                           │
       │ │ Accounts:                                                 │
       │ │ - registry_pda: [b"registry"]                             │
       │ │ - meter_account_pda: [b"meter", owner, meter_serial]      │
       │ │ - gateway_authority: [SIGNER]                             │
       │ │                                                           │
       │ │ Data:                                                     │
       │ │ - discriminator: sha256("global:register_meter")[:8]      │
       │ │ - meter_type: 1 (residential)                             │
       │ │ - owner: user's wallet address                            │
       │ │ - meter_serial: "15165c03-bfaa-4ce9-b3a9-ef09090c18f0"    │
       │ └───────────────────────────────────────────────────────────┘
       │
       │ Anchor Program Logic:
       │ 1. Create MeterAccount PDA
       │ 2. Set owner, meter_serial, meter_type
       │ 3. Initialize reading counters to 0
       │ 4. Emit event: MeterRegistered
       │
       │ Transaction Signature: 4RstUvW... (example)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  3.8 Update Database (On-Chain Signature)                        │
    │      File: registration.rs → sqlx::query!(UPDATE meters)         │
    │      Latency: 5-20ms                                             │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ SQL Update:
       │ UPDATE meters
       │ SET blockchain_tx_signature = '4RstUvW...',
       │     blockchain_registered = true,
       │     updated_at = NOW()
       │ WHERE id = $1
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  3.9 Return Registration Response                                │
    │      File: registration.rs → Ok(Json(RegisterMeterResponse))     │
    │      Total Latency: ~200-500ms                                   │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ HTTP 200 Response:
       │ {
       │   "success": true,
       │   "message": "Meter registered successfully! Your meter is now connected to the grid.",
       │   "meter": {
       │     "id": "meter-uuid",
       │     "serial_number": "15165c03-bfaa-4ce9-b3a9-ef09090c18f0",
       │     "meter_type": "residential",
       │     "location": "123 Solar Street, Bangkok",
       │     "latitude": 13.7563,
       │     "longitude": 100.5018,
       │     "zone_id": 1,
       │     "wallet_address": "9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusV",
       │     "verification_status": "pending",
       │     "blockchain_tx_signature": "4RstUvW..."
       │   }
       │ }
       │
       │ ✅ METER REGISTERED - Can now submit readings
       │
       ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  PHASE 4: FIRST READING SUBMISSION                                       │
│  Endpoint: POST /api/meters/submit-reading                               │
│  Location: gridtokenx-api/src/api/handlers/energy_hdl/readings.rs │
└──────────────────────────────────────────────────────────────────────────┘

    ┌──────────────────────────────────────────────────────────────────┐
    │  4.1 Smart Meter Simulator Sends Reading                         │
    │      Automated: Every 15 minutes (configurable)                  │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ See: data-flow-simulator-to-blockchain.md for complete flow
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  4.2 Reading Processed & Tokens Minted                           │
    │      Background Task: ~320ms                                     │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ User receives GRID tokens based on surplus energy
       │ WebSocket notification sent to connected clients
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  4.3 User Can Trade Energy                                       │
    │      Frontend: Trading UI                                        │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ With registered meter and token balance, user can:
       │ - Submit sell orders (P2P energy trading)
       │ - Submit buy orders
       │ - Participate in auctions
       │ - View earnings dashboard
       │
       └─── ✅ COMPLETE USER ONBOARDING
```

---

## Timeline Summary

### Phase 1: User Registration

| Time | Event | Latency |
|------|-------|---------|
| **T+0ms** | User submits registration form | - |
| **T+50ms** | Password hashed (Argon2id) | ~50ms |
| **T+60ms** | Solana keypair generated | ~10ms |
| **T+80ms** | Private key encrypted | ~20ms |
| **T+100ms** | User inserted to database | ~20ms |
| **T+100ms** | SOL airdrop task spawned (async) | < 1ms |
| **T+105ms** | JWT token generated | ~5ms |
| **T+105ms** | Email sending task spawned (async) | < 1ms |
| **T+200-500ms** | ✅ **Registration complete** | ~200-500ms total |

### Phase 2: Email Verification

| Time | Event | Latency |
|------|-------|---------|
| **T+0ms** | User clicks verification link | - |
| **T+20ms** | Token validated in database | ~20ms |
| **T+40ms** | User record updated | ~20ms |
| **T+50ms** | ✅ **Email verified** | ~50ms total |

### Phase 3: Meter Registration

| Time | Event | Latency |
|------|-------|---------|
| **T+0ms** | User submits meter registration | - |
| **T+5ms** | JWT token validated | ~5ms |
| **T+25ms** | User eligibility checked | ~20ms |
| **T+45ms** | Meter serial uniqueness checked | ~20ms |
| **T+145ms** | Simulator lookup (optional) | ~100ms |
| **T+165ms** | Meter inserted to database | ~20ms |
| **T+365ms** | On-chain registration sent | ~200ms |
| **T+385ms** | Database updated with signature | ~20ms |
| **T+400ms** | ✅ **Meter registered** | ~400ms total |

---

## Database Schema

### Users Table

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'user',
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    
    -- Account status
    is_active BOOLEAN NOT NULL DEFAULT true,
    email_verified BOOLEAN NOT NULL DEFAULT false,
    blockchain_registered BOOLEAN NOT NULL DEFAULT false,
    
    -- Wallet (auto-generated during registration)
    wallet_address VARCHAR(255) UNIQUE,
    encrypted_private_key BYTEA,  -- AES-256-GCM encrypted
    wallet_salt BYTEA,            -- 16 bytes
    encryption_iv BYTEA,          -- 12 bytes
    
    -- Balances
    balance DECIMAL(20, 9) DEFAULT 0,  -- GRX tokens
    locked_amount DECIMAL(20, 9) DEFAULT 0,
    locked_energy DECIMAL(20, 9) DEFAULT 0,
    
    -- Email verification
    email_verification_token VARCHAR(255),
    email_verification_sent_at TIMESTAMPTZ,
    email_verification_expires_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_wallet ON users(wallet_address);
CREATE INDEX idx_users_email_token ON users(email_verification_token);
```

### Meters Table

```sql
CREATE TABLE meters (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    serial_number VARCHAR(255) UNIQUE NOT NULL,
    meter_type VARCHAR(50) NOT NULL,  -- residential, commercial, industrial
    location TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    zone_id INTEGER REFERENCES zones(id),
    
    -- Verification status
    is_verified BOOLEAN NOT NULL DEFAULT false,
    verified_at TIMESTAMPTZ,
    verified_by UUID REFERENCES users(id),
    
    -- Blockchain integration
    blockchain_tx_signature VARCHAR(255),
    blockchain_registered BOOLEAN NOT NULL DEFAULT false,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_meters_user ON meters(user_id);
CREATE INDEX idx_meters_serial ON meters(serial_number);
CREATE INDEX idx_meters_zone ON meters(zone_id);
```

---

## API Endpoints

### User Registration

```http
POST /api/v1/users
Content-Type: application/json

{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "SecureP@ssw0rd!",
  "first_name": "John",
  "last_name": "Doe"
}
```

**Response:**
```json
{
  "message": "Registration successful! 🎉 We've added 20 GRX to your account. Please check your email to verify your account.",
  "email_verification_sent": true,
  "auth": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 86400,
    "user": {
      "id": "user-uuid",
      "username": "john_doe",
      "email": "john@example.com",
      "wallet_address": "9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusV",
      "balance": 20.0
    }
  }
}
```

### Email Verification

```http
GET /api/v1/auth/verify-email?token=550e8400-e29b-41d4-a716-446655440000
```

**Response:**
```json
{
  "success": true,
  "message": "Email verified successfully! You can now register meters and trade energy.",
  "wallet_address": "9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusV"
}
```

### Meter Registration

```http
POST /api/v1/meters
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "serial_number": "15165c03-bfaa-4ce9-b3a9-ef09090c18f0",
  "meter_type": "residential",
  "location": "123 Solar Street, Bangkok",
  "latitude": 13.7563,
  "longitude": 100.5018,
  "zone_id": 1
}
```

**Response:**
```json
{
  "success": true,
  "message": "Meter registered successfully! Your meter is now connected to the grid.",
  "meter": {
    "id": "meter-uuid",
    "serial_number": "15165c03-bfaa-4ce9-b3a9-ef09090c18f0",
    "meter_type": "residential",
    "location": "123 Solar Street, Bangkok",
    "wallet_address": "9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusV",
    "verification_status": "pending",
    "blockchain_tx_signature": "4RstUvW..."
  }
}
```

---

## Security Features

### Password Security

| Feature | Implementation |
|---------|----------------|
| **Hashing Algorithm** | Argon2id (OWASP recommended) |
| **Memory Cost** | 64 MB |
| **Time Cost** | 3 iterations |
| **Parallelism** | 4 threads |
| **Salt** | Random 16 bytes |

### Wallet Security

| Feature | Implementation |
|---------|----------------|
| **Key Generation** | Ed25519 (Solana standard) |
| **Encryption** | AES-256-GCM |
| **Key Derivation** | PBKDF2 or HKDF |
| **Secret Sharding** | Master secret + user password |
| **Storage** | Encrypted private key + salt + IV |

### Token Security

| Feature | Implementation |
|---------|----------------|
| **JWT Algorithm** | HS256 or RS256 |
| **Expiry** | 24 hours (configurable) |
| **Refresh Tokens** | Supported (optional) |
| **Email Verification** | UUID v4, 24-hour expiry |

---

## Error Handling

### Registration Errors

| Error | HTTP Status | Message |
|-------|-------------|---------|
| Username taken | 400 | "Username already exists" |
| Email taken | 400 | "Email already registered" |
| Weak password | 400 | "Password does not meet requirements" |
| Invalid email | 400 | "Invalid email format" |
| Database error | 500 | "Failed to create user" |

### Email Verification Errors

| Error | HTTP Status | Message |
|-------|-------------|---------|
| Token not found | 404 | "Invalid verification token" |
| Token expired | 400 | "Verification token has expired" |
| Already verified | 200 | "Email is already verified" |

### Meter Registration Errors

| Error | HTTP Status | Message |
|-------|-------------|---------|
| Email not verified | 403 | "Email must be verified first" |
| Meter already registered | 400 | "Meter serial already registered" |
| Invalid zone | 400 | "Invalid zone ID" |
| Simulator lookup failed | 500 | "Failed to verify meter in simulator" |

---

## Testing

### Manual Testing

```bash
# 1. Register new user
curl -X POST http://localhost:4001/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "test_user",
    "email": "test@example.com",
    "password": "TestP@ssw0rd!",
    "first_name": "Test",
    "last_name": "User"
  }'

# 2. Verify email (extract token from email or database)
curl -X GET "http://localhost:4001/api/v1/auth/verify-email?token=<token>"

# 3. Login to get JWT
curl -X POST http://localhost:4001/api/v1/auth/token \
  -H "Content-Type: application/json" \
  -d '{
    "username": "test_user",
    "password": "TestP@ssw0rd!"
  }'

# 4. Register meter (use JWT from login)
curl -X POST http://localhost:4001/api/v1/meters \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <JWT>" \
  -d '{
    "serial_number": "test-meter-001",
    "meter_type": "residential",
    "zone_id": 1
  }'
```

### Automated Testing

```bash
# Run integration tests
cd gridtokenx-api
cargo test --test user_registration_test
cargo test --test meter_registration_test
```

---

## Related Documentation

- [Data Flow: Simulator to Blockchain](../specs/system-architecture.md#secure-telemetry-pipeline)
- [Authentication & JWT Design](../specs/authentication-jwt-design.md)
- [Smart Contract Architecture](../specs/smart-contract-architecture.md)
- [P2P Trading Flow](../specs/system-architecture.md#3-high-level-architecture-c4-level-2)
- [Security Analysis](../../academic/07-security-analysis.md)

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-03-16 | Initial implementation with auto-generated wallets |
