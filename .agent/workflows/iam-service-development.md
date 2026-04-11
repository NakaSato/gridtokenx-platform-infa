---
description: Identity and Access Management service development guide
---

# IAM Service Development

The **IAM Service** (`gridtokenx-iam-service`) manages user identity, cryptographic wallet security, and on-chain registration in the Solana **Registry Program**.

## Core Responsibilities
- **Identity & KYC**: User profiles, roles, and compliance status.
- **Wallet Security**: Generation and encryption of user keypairs using a `master_secret`.
- **Blockchain Registry**: Initializing `UserAccount` and `MeterAccount` PDAs.
- **ConnectRPC Server**: Provides identity services to the API Gateway.

## Quick Commands

// turbo

```bash
# Run IAM Service natively
cd gridtokenx-iam-service && cargo run

# Run tests
cargo test -p gridtokenx-iam-service
```

## Project Structure

```
gridtokenx-iam-service/src/
├── api/                # gRPC / ConnectRPC Handlers
├── domain/             # Registry logic & Identity models
│   ├── identity/      # User & Role domain logic
│   └── registration/  # Blockchain registration flows
├── infra/              # External persistence
│   ├── solana/         # Anchor client & Wallet utilities
│   └── database/       # SQLx persistence
├── core/               # App configuration & encryption constants
└── startup.rs          # Service & Connection pooling
```

## Key Workflows

### 1. User Wallet Encryption
user private keys are NEVER stored in plain text. They are encrypted using `AES-256-GCM` with a `master_secret` derived from the environment.

```rust
// domain/identity/wallet.rs
pub async fn create_secure_wallet(secret: &str) -> EncryptedWallet {
    let keypair = Keypair::new();
    let encrypted = encrypt_keypair(&keypair, secret)?;
    // Store encrypted in DB
}
```

### 2. Blockchain Registration
When a user is verified, the IAM service registers them on-chain:

```rust
// domain/registration/registry.rs
pub async fn register_user_on_chain(state: AppState, user_id: Uuid) -> Result<()> {
    // 1. Decrypt user wallet
    // 2. Build Anchor instruction for registry_program::initialize_user
    // 3. Sign and send transaction to Solana
}
```

## gRPC API
The IAM service exposes endpoints defined in `proto/iam.proto`:
- `RegisterUser`: Create profile and wallet.
- `GetIdentity`: Retrieve user roles and KYC status.
- `VerifyKYC`: Update on-chain compliance state.

## Configuration
Essential `.env` variables for IAM:
- `ENCRYPTION_MASTER_SECRET`: 32-byte key for wallet security.
- `SOLANA_RPC_URL`: Endpoint for blockchain transactions.
- `REGISTRY_PROGRAM_ID`: The Program ID of the Anchor registry.

## Related Workflows
- [API Development](./api-development.md) - How the gateway calls IAM.
- [Anchor Development](./anchor-development.md) - Working on the Registry smart contract.
- [Blockchain Init](./blockchain-init.md) - Deploying the Registry program.
