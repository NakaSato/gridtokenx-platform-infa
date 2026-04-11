# 🛡 IAM Service Architecture

**Service Name**: `gridtokenx-iam-service`  
**Port**: `50052` (gRPC) / `8081` (REST)  
**Version**: 2.2  
**Status**: ✅ Production Ready

---

## 1. Overview

The **IAM (Identity & Access Management) Service** is the guardian of identity and ownership within the GridTokenX Platform. It bridges the gap between off-chain user accounts and on-chain Solana identities. It is the only service authorized to perform user registration, KYC status management, and secure wallet custody.

---

## 2. Core Responsibilities

1.  **Identity Management**: Handles user signup, login, and Role-Based Access Control (RBAC: Prosumer, Consumer, Validator).
2.  **Secure Wallet Custody**: 
    -   Generates Ed25519 keypairs for every user.
    -   Encrypts private keys using **AES-256-GCM** with a master secret injected via environment variables.
3.  **Blockchain Registry**:
    -   Manages the **Registry Program** (`FmvDi...89c`).
    -   Initializes `UserAccount` and `MeterAccount` PDAs.
4.  **KYC Lifecycle**: Orchestrates document submission status and updates on-chain verification flags.
5.  **Session Management**: Issues scoped JWTs that are validated at the Kong API Gateway entry point.

---

## 3. Technical Stack

-   **Framework**: Rust (Tonic for gRPC / Axum for REST)
-   **Database**: PostgreSQL 17 (Shared IAM Schema)
-   **Blockchain**: `solana-sdk`, `anchor-client`
-   **Security**: 
    -   `argon2id`: Industry-standard password hashing.
    -   `aes-gcm`: Authenticated encryption for all stored keys.
    -   `jsonwebtoken`: Scoped access tokens for platform-wide auth.

---

## 4. Blockchain Interactions (Registry Program)

The IAM Service is the primary owner of the **Registry Program** (`FmvDiFUWPrwXsqo7z7XnVniKbZDcz32U5HSDVwPug89c`).

### Principal PDAs (Program-Derived Addresses)
-   **UserAccount**: `["user", user_uuid]` - Stores user identity, role, and KYC status.
-   **MeterAccount**: `["meter", meter_pubkey]` - Links a physical meter to its on-chain owner.

### Critical Instructions
-   `initialize_user`: Creates the on-chain identity record for a new platform UUID.
-   `register_meter`: Securely links a physical meter's public key to a user's on-chain account.
-   `update_kyc_status`: Flips the `is_verified` bit after compliance checks.

---

## 5. Security Model

> [!IMPORTANT]
> **Private Key Isolation**: Private keys are **never stored in plain text**. They are encrypted using the `WalletService` during generation and only decrypted in-memory during transaction signing. The `MASTER_SECRET` must be rotated annually and never exported.

1.  **Zero-Knowledge Context**: The database only sees encrypted blobs; the service only sees plain text in volatile memory.
2.  **ConnectRPC Security**: Incoming gRPC requests are validated against internal service-to-service tokens.

---

## 6. Directory Structure

```text
gridtokenx-iam-service/src/
├── main.rs              # gRPC/REST Server Entry
├── core/                # Shared config & encryption logic
├── domain/              # Business Logic
│   ├── identity/        # User accounts & RBAC
│   ├── wallet/          # Ed25519 key management & AES-GCM
│   └── kyc/             # Verification workflows
├── infra/               # External Integrations
│   ├── db/              # SQLx / Postgres persistence
│   └── solana/          # Anchor Client / Registry Program
└── api/                 # ConnectRPC / Tonic implementation
```

---

## Related Documentation
-   [Platform Design](../../PLATFORM_DESIGN.md)
-   [System Architecture](../specs/system-architecture.md)
-   [Blockchain Architecture](../specs/blockchain-architecture.md)
