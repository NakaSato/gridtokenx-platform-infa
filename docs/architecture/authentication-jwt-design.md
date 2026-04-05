# Authentication & JWT Design

**Version:** 1.0  
**Last Updated:** March 16, 2026  
**Authors:** GridTokenX Engineering Team

---

## Overview

This document describes the authentication and authorization architecture for the GridTokenX platform, including JWT token design, API key authentication for AMI systems, and role-based access control (RBAC).

### Key Features

| Feature | Implementation | Benefit |
|---------|----------------|---------|
| **JWT Authentication** | HS256 algorithm with 24h expiry | Stateless, scalable authentication |
| **API Key Support** | HMAC-SHA256 signed keys | AMI (Advanced Metering Infrastructure) integration |
| **Role-Based Access** | Admin, User, AMI roles | Fine-grained permission control |
| **Impersonation** | Engineering key + X-Impersonate-User header | Debugging and support |
| **Secure Password Storage** | Argon2id hashing | OWASP recommended protection |
| **Wallet Encryption** | AES-256-GCM with secret sharding | Bank-level key security |

---

## Authentication Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    AUTHENTICATION ARCHITECTURE                           │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│  METHOD 1: JWT AUTHENTICATION (Standard Users)                           │
│  Header: Authorization: Bearer <JWT_TOKEN>                               │
│  Location: gridtokenx-api/src/api/middleware/auth.rs              │
└──────────────────────────────────────────────────────────────────────────┘

    ┌──────────────────────────────────────────────────────────────────┐
    │  1.1 User Logs In                                                │
    │      Endpoint: POST /api/v1/auth/token                           │
    │      File: login.rs → login()                                    │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Request:
       │ {
       │   "username": "john_doe",
       │   "password": "SecureP@ssw0rd!"
       │ }
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.2 Query User from Database                                    │
    │      Latency: 5-20ms                                             │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ SQL Query:
       │ SELECT id, username, email, password_hash, role,
       │        first_name, last_name, wallet_address,
       │        balance, locked_amount, locked_energy
       │ FROM users
       │ WHERE (username = $1 OR email = $1) AND is_active = true
       │ LIMIT 1
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.3 Verify Password (Argon2id)                                  │
    │      File: password.rs → PasswordService::verify_password()      │
    │      Latency: ~50-100ms (spawn_blocking)                         │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Uses tokio::task::spawn_blocking to avoid blocking async runtime
       │ Password hashed with Argon2id (OWASP recommended)
       │
       │ If invalid:
       │ → Return 401 Unauthorized
       │ → Log failed attempt
       │ → Track metrics
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.4 Decrypt Wallet (Optional Verification)                      │
    │      File: login.rs → WalletService::decrypt_private_key()       │
    │      Latency: ~10-20ms                                           │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Derives decryption key from:
       │ - Master secret (environment variable)
       │ - User password (not stored)
       │
       │ Purpose: Verify wallet is accessible
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.5 Generate JWT Claims                                         │
    │      File: auth.rs → Claims::new()                               │
    │      Latency: < 1ms                                              │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Claims Structure:
       │ {
       │   "sub": "user-uuid",              // Subject (user ID)
       │   "username": "john_doe",          // Username
       │   "role": "user",                  // Role (user, admin, ami)
       │   "exp": 1710686400,               // Expiration (24 hours)
       │   "iat": 1710600000,               // Issued at
       │   "iss": "api-gateway"             // Issuer
       │ }
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.6 Encode JWT Token (HS256)                                    │
    │      File: jwt.rs → JwtService::encode_token()                   │
    │      Latency: < 5ms                                              │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ JWT Structure:
       │ Header: {"alg": "HS256", "typ": "JWT"}
       │ Payload: {claims from step 1.5}
       │ Signature: HMAC-SHA256(header + payload, JWT_SECRET)
       │
       │ Final Token: base64(header).base64(payload).base64(signature)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.7 Return Authentication Response                              │
    │      File: login.rs → Ok(Json(AuthResponse))                     │
    │      Total Latency: ~100-200ms                                   │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ HTTP 200 Response:
       │ {
       │   "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
       │   "expires_in": 86400,
       │   "user": {
       │     "id": "user-uuid",
       │     "username": "john_doe",
       │     "email": "john@example.com",
       │     "role": "user",
       │     "wallet_address": "9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusV",
       │     "balance": 20.0,
       │     "locked_amount": 0.0,
       │     "locked_energy": 0.0
       │   }
       │ }
       │
       ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  METHOD 2: API KEY AUTHENTICATION (AMI / Smart Meters)                   │
│  Header: X-API-Key: <API_KEY>                                            │
│  Location: gridtokenx-api/src/api/middleware/auth.rs              │
└──────────────────────────────────────────────────────────────────────────┘

    ┌──────────────────────────────────────────────────────────────────┐
    │  2.1 Smart Meter Sends Request with API Key                      │
    │      Use Case: Automated meter readings, telemetry               │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Request Headers:
       │ X-API-Key: ak_1234567890abcdef
       │ Content-Type: application/json
       │
       │ Example:
       │ POST /api/meters/submit-reading
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  2.2 Validate API Key                                            │
    │      File: auth.rs → auth_middleware()                           │
    │      Latency: < 5ms                                              │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Validation:
       │ 1. Check if API key matches engineering_api_key config
       │ 2. If match → Create synthetic claims with "ami" role
       │ 3. Allow impersonation via X-Impersonate-User header
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  2.3 (Optional) Impersonate User                                 │
    │      Header: X-Impersonate-User: <user-uuid>                     │
    │      Latency: < 5ms                                              │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Use Case: Simulator acting on behalf of specific user
       │
       │ Process:
       │ 1. Parse user UUID from header
       │ 2. Create claims with impersonated user ID
       │ 3. Keep "ami" role for audit trail
       │
       │ Claims:
       │ {
       │   "sub": "impersonated-user-uuid",
       │   "username": "simulator",
       │   "role": "ami"
       │ }
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  2.4 Create Synthetic Claims                                     │
    │      File: auth.rs → Claims::new()                               │
    │      Latency: < 1ms                                              │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ For AMI without impersonation:
       │ {
       │   "sub": "simulator-uuid",        // From config.simulator_user_id
       │   "username": "simulator",
       │   "role": "ami"
       │ }
       │
       │ For AMI with impersonation:
       │ {
       │   "sub": "user-uuid",             // From X-Impersonate-User
       │   "username": "simulator",
       │   "role": "ami"
       │ }
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  2.5 Add Claims to Request Extensions                            │
    │      File: auth.rs → request.extensions_mut().insert(claims)     │
    │      Latency: < 1ms                                              │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Claims available to handlers via:
       │ AuthenticatedUser(claims): AuthenticatedUser extractor
       │
       │ Handler example:
       │ pub async fn submit_reading(
       │     State(state): State<AppState>,
       │     AuthenticatedUser(user): AuthenticatedUser,  // ← Extracts claims
       │     Json(request): Json<SubmitReadingRequest>,
       │ ) -> Result<Json<MeterReadingResponse>> {
       │     let user_id = user.sub;  // Access user ID
       │     let role = user.role;    // Access role
       │     // ...
       │ }
       │
       ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  METHOD 3: ENGINEERING KEY (Debugging & Support)                         │
│  Header: Authorization: Bearer <ENGINEERING_KEY>                         │
│  Location: gridtokenx-api/src/api/middleware/auth.rs              │
└──────────────────────────────────────────────────────────────────────────┘

    ┌──────────────────────────────────────────────────────────────────┐
    │  3.1 Engineering Key Authentication                              │
    │      Use Case: Debugging, support, testing                       │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Request Headers:
       │ Authorization: Bearer <engineering_api_key>
       │ X-Impersonate-User: <user-uuid>  // Optional
       │
       │ Engineering key configured via:
       │ ENGINEERING_API_KEY environment variable
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  3.2 Match Engineering Key                                       │
    │      File: auth.rs → auth_middleware()                           │
    │      Latency: < 5ms                                              │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Validation:
       │ if token == state.config.engineering_api_key {
       │     // Engineering key matched!
       │     // Allow impersonation
       │ }
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  3.3 Impersonate Any User                                        │
    │      File: auth.rs → auth_middleware()                           │
    │      Latency: < 5ms                                              │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Process:
       │ 1. Check X-Impersonate-User header
       │ 2. Parse user UUID
       │ 3. Create claims with impersonated user ID
       │ 4. Use "ami" role for audit trail
       │
       │ Security:
       │ - Only engineering key can impersonate
       │ - All impersonation logged
       │ - Metrics tracked for audit
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  3.4 Create Synthetic Claims                                     │
    │      File: auth.rs → Claims::new()                               │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Claims:
       │ {
       │   "sub": "impersonated-user-uuid",
       │   "username": "simulator",
       │   "role": "ami"
       │ }
       │
       ▼
```

---

## JWT Token Structure

### Header

```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

### Payload (Claims)

```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",
  "username": "john_doe",
  "role": "user",
  "exp": 1710686400,
  "iat": 1710600000,
  "iss": "api-gateway"
}
```

### Claims Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| **sub** | UUID | Subject (user ID) | `550e8400-e29b-41d4-a716-446655440000` |
| **username** | String | Username | `john_doe` |
| **role** | String | User role | `user`, `admin`, `ami` |
| **exp** | i64 | Expiration timestamp | `1710686400` |
| **iat** | i64 | Issued at timestamp | `1710600000` |
| **iss** | String | Issuer | `api-gateway` |

### Signature

```
HMAC-SHA256(
  base64UrlEncode(header) + "." + base64UrlEncode(payload),
  JWT_SECRET
)
```

---

## Role-Based Access Control (RBAC)

### Roles

| Role | Description | Use Case |
|------|-------------|----------|
| **user** | Standard platform user | Energy traders, prosumers, consumers |
| **admin** | Platform administrator | Support staff, system operators |
| **ami** | Automated Metering Infrastructure | Smart meters, simulators, IoT devices |

### Permissions

```rust
pub enum Permission {
    // User permissions
    EnergyRead,
    EnergyWrite,
    TradingCreate,
    TradingRead,
    MeterRegister,
    MeterRead,
    
    // Admin permissions
    UsersCreate,
    UsersRead,
    UsersUpdate,
    UsersDelete,
    AdminSettings,
    SystemMetrics,
    
    // AMI permissions
    MeterSubmitReading,
    MeterTelemetry,
    ImpersonateUser,
}
```

### Permission Matrix

| Permission | user | admin | ami |
|------------|------|-------|-----|
| `energy:read` | ✅ | ✅ | ✅ |
| `energy:write` | ✅ | ✅ | ✅ |
| `trading:create` | ✅ | ✅ | ❌ |
| `trading:read` | ✅ | ✅ | ✅ |
| `meter:register` | ✅ | ✅ | ✅ |
| `meter:submit_reading` | ✅ | ✅ | ✅ |
| `users:create` | ❌ | ✅ | ❌ |
| `users:read` | ❌ | ✅ | ❌ |
| `admin:settings` | ❌ | ✅ | ❌ |
| `system:metrics` | ❌ | ✅ | ✅ |
| `impersonate:user` | ❌ | ✅ | ✅ |

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

### JWT Security

| Feature | Implementation |
|---------|----------------|
| **Algorithm** | HS256 (HMAC-SHA256) |
| **Secret** | 256-bit random key (JWT_SECRET env var) |
| **Expiration** | 24 hours (configurable) |
| **Issuer Validation** | Must be "api-gateway" |
| **Signature Verification** | Automatic on decode |

### API Key Security

| Feature | Implementation |
|---------|----------------|
| **Format** | `ak_` prefix + UUID (no dashes) |
| **Storage** | Hashed with HMAC-SHA256 |
| **Rotation** | Supported (generate new key) |
| **Revocation** | Set is_active = false |

### Wallet Encryption

| Feature | Implementation |
|---------|----------------|
| **Algorithm** | AES-256-GCM |
| **Key Derivation** | PBKDF2 or HKDF |
| **Secret Sharding** | Master secret + user password |
| **Salt** | Random 16 bytes |
| **IV** | Random 12 bytes |

---

## Code Examples

### Generating JWT Token

```rust
use crate::domain::identity::{Claims, JwtService};
use uuid::Uuid;

// Create claims
let claims = Claims::new(
    Uuid::new_v4(),           // user_id
    "john_doe".to_string(),   // username
    "user".to_string(),       // role
);

// Encode token
let jwt_service = JwtService::new()?;
let token = jwt_service.encode_token(&claims)?;

// Token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Verifying JWT Token

```rust
use crate::domain::identity::JwtService;

let jwt_service = JwtService::new()?;

// Decode and verify
let claims = jwt_service.decode_token(&token)?;

// Access claims
println!("User ID: {}", claims.sub);
println!("Username: {}", claims.username);
println!("Role: {}", claims.role);
println!("Expired: {}", claims.is_expired());
```

### Role-Based Authorization

```rust
use axum::extract::State;
use crate::api::middleware::AuthenticatedUser;
use crate::domain::identity::Claims;

pub async fn admin_only_endpoint(
    State(state): State<AppState>,
    AuthenticatedUser(claims): AuthenticatedUser,
) -> Result<Json<Response>> {
    // Check role
    if !claims.has_role("admin") {
        return Err(ApiError::Forbidden("Admin access required".to_string()));
    }
    
    // Admin-only logic here
    Ok(Json(response))
}

pub async fn user_or_admin_endpoint(
    State(state): State<AppState>,
    AuthenticatedUser(claims): AuthenticatedUser,
) -> Result<Json<Response>> {
    // Check multiple roles
    if !claims.has_any_role(&["user", "admin"]) {
        return Err(ApiError::Forbidden("User or admin access required".to_string()));
    }
    
    // Logic here
    Ok(Json(response))
}
```

### API Key Authentication (AMI)

```rust
// Smart meter sends request with API key
curl -X POST http://localhost:4001/api/meters/submit-reading \
  -H "X-API-Key: ak_1234567890abcdef" \
  -H "Content-Type: application/json" \
  -d '{
    "meter_serial": "15165c03-bfaa-4ce9-b3a9-ef09090c18f0",
    "kwh": 5.234
  }'

// With impersonation (act as specific user)
curl -X POST http://localhost:4001/api/meters/submit-reading \
  -H "X-API-Key: ak_1234567890abcdef" \
  -H "X-Impersonate-User: 550e8400-e29b-41d4-a716-446655440000" \
  -H "Content-Type: application/json" \
  -d '{...}'
```

---

## Database Schema

### Users Table

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'user',  -- user, admin, ami
    
    -- Account status
    is_active BOOLEAN NOT NULL DEFAULT true,
    email_verified BOOLEAN NOT NULL DEFAULT false,
    blockchain_registered BOOLEAN NOT NULL DEFAULT false,
    
    -- Wallet
    wallet_address VARCHAR(255) UNIQUE,
    encrypted_private_key BYTEA,
    wallet_salt BYTEA,
    encryption_iv BYTEA,
    
    -- Balances
    balance DECIMAL(20, 9) DEFAULT 0,
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

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
```

### API Keys Table (Optional for AMI)

```sql
CREATE TABLE api_keys (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    key_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    permissions JSONB NOT NULL DEFAULT '[]',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_used_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ
);

CREATE INDEX idx_api_keys_hash ON api_keys(key_hash);
CREATE INDEX idx_api_keys_user ON api_keys(user_id);
CREATE INDEX idx_api_keys_active ON api_keys(is_active);
```

---

## Error Handling

### Authentication Errors

| Error | HTTP Status | Message |
|-------|-------------|---------|
| Missing Authorization header | 401 | "Missing or invalid Authorization header" |
| Invalid JWT signature | 401 | "Invalid token signature" |
| Expired JWT | 401 | "Token has expired" |
| Invalid API key | 401 | "Invalid API key" |
| User not found | 401 | "User not found" |
| Invalid password | 401 | "Invalid credentials" |

### Authorization Errors

| Error | HTTP Status | Message |
|-------|-------------|---------|
| Insufficient permissions | 403 | "Forbidden: insufficient permissions" |
| Email not verified | 403 | "Email must be verified first" |
| Account inactive | 403 | "Account is deactivated" |

---

## Testing

### Manual Testing

```bash
# 1. Register user
curl -X POST http://localhost:4001/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "test_user",
    "email": "test@example.com",
    "password": "TestP@ssw0rd!",
    "first_name": "Test",
    "last_name": "User"
  }'

# 2. Login to get JWT
curl -X POST http://localhost:4001/api/v1/auth/token \
  -H "Content-Type: application/json" \
  -d '{
    "username": "test_user",
    "password": "TestP@ssw0rd!"
  }'

# Response:
# {
#   "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
#   "expires_in": 86400,
#   "user": {...}
# }

# 3. Use JWT in subsequent requests
curl -X GET http://localhost:4001/api/v1/users/me \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# 4. Test API key authentication (AMI)
curl -X POST http://localhost:4001/api/meters/submit-reading \
  -H "X-API-Key: ak_test_key_1234567890" \
  -H "Content-Type: application/json" \
  -d '{
    "meter_serial": "test-meter-001",
    "kwh": 5.234
  }'

# 5. Test impersonation (Engineering key only)
curl -X GET http://localhost:4001/api/v1/users/me \
  -H "Authorization: Bearer <engineering_api_key>" \
  -H "X-Impersonate-User: 550e8400-e29b-41d4-a716-446655440000"
```

### Automated Testing

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::identity::{Claims, JwtService};
    use uuid::Uuid;

    #[test]
    fn test_jwt_encode_decode() {
        // Setup
        unsafe {
            std::env::set_var("JWT_SECRET", "test_secret_key_123456789");
        }

        let jwt_service = JwtService::new().unwrap();
        let claims = Claims::new(
            Uuid::new_v4(),
            "test_user".to_string(),
            "user".to_string(),
        );

        // Encode
        let token = jwt_service.encode_token(&claims).unwrap();

        // Decode
        let decoded_claims = jwt_service.decode_token(&token).unwrap();

        // Assert
        assert_eq!(claims.sub, decoded_claims.sub);
        assert_eq!(claims.username, decoded_claims.username);
        assert_eq!(claims.role, decoded_claims.role);
        assert!(!claims.is_expired());
    }

    #[test]
    fn test_role_permissions() {
        let admin = Role::Admin;
        assert!(admin.can_access("users:create"));
        assert!(admin.can_access("energy:read"));
        assert!(admin.can_access("admin:settings"));

        let user = Role::User;
        assert!(user.can_access("energy:read"));
        assert!(user.can_access("trading:create"));
        assert!(!user.can_access("users:create"));
        assert!(!user.can_access("admin:settings"));
    }
}
```

---

## Related Documentation

- [User Registration Workflow](./user-registration-workflow.md)
- [P2P Trading Flow](./p2p-trading-flow.md)
- [Smart Contract Architecture](./smart-contract-architecture.md)
- [Security Best Practices](./security-best-practices.md)

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-03-16 | Initial implementation with JWT + API key support |
