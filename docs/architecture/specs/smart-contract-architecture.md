# Smart Contract Architecture

**Version:** 1.0  
**Last Updated:** March 16, 2026  
**Authors:** GridTokenX Engineering Team

---

## Overview

This document describes the Solana Anchor smart contract architecture for the GridTokenX P2P energy trading platform, including program structure, account layouts, instruction flows, and cross-program interactions.

### Platform Programs

| Program | ID | Purpose | Language |
|---------|-----|---------|----------|
| **Registry** | `FmvDiFUWPrwXsqo7z7XnVniKbZDcz32U5HSDVwPug89c` | User & meter registration, identity management | Rust (Anchor) |
| **Energy Token** | `n52aKuZwUeZAocpWqRZAJR4xFhQqAvaRE7Xepy2JBGk` | GRID token (energy-backed ERC-20 equivalent) | Rust (Anchor) |
| **Trading** | `69dGpKu9a8EZiZ7orgfTH6CoGj9DeQHHkHBF2exSr8na` | Order book, matching, escrow, settlement | Rust (Anchor) |
| **Oracle** | `JDUVXMkeGi4oxLp8njBaGScAFaVBBg7iGoiqcY1LxKop` | Price feeds, grid data, external data verification | Rust (Anchor) |
| **Governance** | `DamT9e1VqbA5nSyFZHExKwQu6qs4L5FW6dirWCK8YLd4` | Protocol upgrades, parameter changes, REC management | Rust (Anchor) |

---

## Registry Program

**Location:** `gridtokenx-anchor/programs/registry/src/lib.rs`  
**Purpose:** User and meter registration, identity management, REC (Renewable Energy Certificate) tracking

### Program ID
```
FmvDiFUWPrwXsqo7z7XnVniKbZDcz32U5HSDVwPug89c
```

### Accounts

#### Registry (PDA)

```rust
#[account]
pub struct Registry {
    pub authority: Pubkey,              // Admin authority
    pub oracle_authority: Pubkey,       // Oracle authorized to update readings
    pub has_oracle_authority: u8,       // Flag: oracle authority set
    pub user_count: u64,                // Total registered users
    pub meter_count: u64,               // Total registered meters
    pub active_meter_count: u64,        // Active meters
}
```

**PDA Seeds:**
```rust
[b"registry"]
```

#### UserAccount (PDA)

```rust
#[account]
pub struct UserAccount {
    pub user: Pubkey,                   // User's wallet address
    pub user_type: UserType,            // Prosumer, Consumer, Prosumer2, etc.
    pub lat_e7: i32,                    // Latitude * 10^7 (fixed precision)
    pub long_e7: i32,                   // Longitude * 10^7
    pub h3_index: u64,                  // H3 geospatial index
    pub meter_count: u64,               // Number of meters owned
    pub total_energy_generated: u64,    // Lifetime generation (Wh)
    pub total_energy_consumed: u64,     // Lifetime consumption (Wh)
    pub created_at: i64,                // Registration timestamp
}
```

**PDA Seeds:**
```rust
[b"user", user.key().as_ref()]
```

#### MeterAccount (PDA)

```rust
#[account]
pub struct MeterAccount {
    pub owner: Pubkey,                  // Owner's wallet address
    pub meter_id: [u8; 32],             // Meter serial number (fixed bytes)
    pub meter_type: MeterType,          // Residential, Commercial, Industrial
    pub location: [u8; 32],             // Location description
    pub latitude: Option<f64>,          // GPS latitude
    pub longitude: Option<f64>,         // GPS longitude
    pub is_verified: bool,              // Admin verified
    pub last_reading_generated: u64,    // Last reading (Wh generated)
    pub last_reading_consumed: u64,     // Last reading (Wh consumed)
    pub last_reading_timestamp: i64,    // Last reading timestamp
    pub total_generated: u64,           // Lifetime generation
    pub total_consumed: u64,            // Lifetime consumption
    pub created_at: i64,                // Registration timestamp
}
```

**PDA Seeds:**
```rust
[b"meter", owner.key().as_ref(), meter_id.as_ref()]
```

### Instructions

#### Initialize Registry

```rust
pub fn initialize(ctx: Context<Initialize>) -> Result<()>
```

**Accounts:**
- `registry` (PDA): `[b"registry"]`
- `authority` (Signer): Admin authority
- `system_program`: System program

**Logic:**
1. Initialize Registry PDA
2. Set authority
3. Initialize counters to 0

---

#### Register User

```rust
pub fn register_user(
    ctx: Context<RegisterUser>,
    user_type: UserType,
    lat_e7: i32,
    long_e7: i32,
    h3_index: u64,
    shard_id: u8,
) -> Result<()>
```

**Accounts:**
- `user_account` (PDA): `[b"user", user.key().as_ref()]`
- `user` (Signer): User's wallet
- `registry` (PDA): `[b"registry"]`
- `grid_token_mint`: GRID token mint
- `user_ata`: User's GRID token account
- `token_program`: SPL Token program

**Logic:**
1. Create UserAccount PDA
2. Store user metadata (location, H3 index)
3. Increment registry user count
4. **Airdrop 20 GRX tokens** to user
5. Emit `UserRegistered` event

**Event:**
```rust
pub struct UserRegistered {
    pub user: Pubkey,
    pub user_type: UserType,
    pub lat_e7: i32,
    pub long_e7: i32,
    pub h3_index: u64,
    pub airdrop_amount: u64,  // 20 GRX
    pub timestamp: i64,
}
```

---

#### Register Meter

```rust
pub fn register_meter(
    ctx: Context<RegisterMeter>,
    meter_id: [u8; 32],
    meter_type: MeterType,
    location: [u8; 32],
) -> Result<()>
```

**Accounts:**
- `meter_account` (PDA): `[b"meter", owner.key().as_ref(), meter_id.as_ref()]`
- `owner` (Signer): Meter owner
- `user_account` (PDA): `[b"user", owner.key().as_ref()]`
- `registry` (PDA): `[b"registry"]`

**Logic:**
1. Create MeterAccount PDA
2. Store meter metadata
3. Link to user account
4. Increment registry meter count
5. Emit `MeterRegistered` event

---

#### Update Meter Reading

```rust
pub fn update_meter_reading(
    ctx: Context<UpdateMeterReading>,
    energy_generated: u64,
    energy_consumed: u64,
    reading_timestamp: i64,
) -> Result<()>
```

**Accounts:**
- `registry` (PDA): `[b"registry"]`
- `meter_account` (PDA): `[b"meter", owner, meter_id]`
- `oracle_authority` (Signer): Authorized oracle

**Logic:**
1. Verify oracle authority
2. Update meter readings
3. Update lifetime totals
4. Emit `MeterReadingUpdated` event

**Event:**
```rust
pub struct MeterReadingUpdated {
    pub meter: Pubkey,
    pub energy_generated: u64,
    pub energy_consumed: u64,
    pub surplus: u64,
    pub timestamp: i64,
}
```

---

## Energy Token Program

**Location:** `gridtokenx-anchor/programs/energy-token/src/lib.rs`  
**Purpose:** GRID token management (minting, burning, transfers)

### Program ID
```
n52aKuZwUeZAocpWqRZAJR4xFhQqAvaRE7Xepy2JBGk
```

### Token Specifications

| Property | Value |
|----------|-------|
| **Name** | GridTokenX |
| **Symbol** | GRX |
| **Decimals** | 9 |
| **Type** | SPL Token-2022 |
| **Metadata** | Metaplex Token Metadata |
| **Mint Authority** | Program PDA |
| **Total Supply** | Dynamic (minted/burned based on energy) |

### Accounts

#### TokenInfo (PDA)

```rust
#[account]
pub struct TokenInfo {
    pub authority: Pubkey,              // Program authority
    pub registry_authority: Pubkey,     // Registry program authority
    pub registry_program: Pubkey,       // Registry program ID
    pub mint: Pubkey,                   // GRID token mint
    pub total_supply: u64,              // Total supply (synced periodically)
    pub created_at: i64,                // Creation timestamp
}
```

**PDA Seeds:**
```rust
[b"token_info_2022"]
```

### Instructions

#### Initialize Token

```rust
pub fn initialize_token(
    ctx: Context<InitializeToken>,
    registry_program_id: Pubkey,
    registry_authority: Pubkey,
) -> Result<()>
```

**Accounts:**
- `token_info` (PDA): `[b"token_info_2022"]`
- `authority` (Signer): Program authority
- `mint`: GRID token mint
- `system_program`: System program

**Logic:**
1. Initialize TokenInfo PDA
2. Link to Registry program
3. Set mint authority

---

#### Mint to Wallet

```rust
pub fn mint_to_wallet(ctx: Context<MintToWallet>, amount: u64) -> Result<()>
```

**Accounts:**
- `token_info` (PDA): `[b"token_info_2022"]`
- `mint`: GRID token mint
- `destination`: User's token account
- `authority` (Signer): Mint authority
- `token_program`: SPL Token program

**Logic:**
1. Verify authority
2. Mint tokens to destination
3. Emit `TokensMinted` event

**Event:**
```rust
pub struct TokensMinted {
    pub recipient: Pubkey,
    pub amount: u64,
    pub timestamp: i64,
}
```

**CPI (Cross-Program Invocation):**
```rust
let cpi_accounts = token_interface::MintTo {
    mint: ctx.accounts.mint.to_account_info(),
    to: ctx.accounts.destination.to_account_info(),
    authority: ctx.accounts.token_info.to_account_info(),
};

let seeds = &[b"token_info_2022".as_ref(), &[ctx.bumps.token_info]];
let signer = &[&seeds[..]];  // PDA signing

let cpi_ctx = CpiContext::new_with_signer(cpi_program, cpi_accounts, signer);
token_interface::mint_to(cpi_ctx, amount)?;
```

---

#### Burn Tokens

```rust
pub fn burn_tokens(ctx: Context<BurnTokens>, amount: u64) -> Result<()>
```

**Accounts:**
- `token_info` (PDA): `[b"token_info_2022"]`
- `mint`: GRID token mint
- `from`: User's token account
- `authority` (Signer): Burn authority
- `token_program`: SPL Token program

**Logic:**
1. Burn tokens from account
2. Update total supply
3. Emit `TokensBurned` event

---

#### Create Token Metadata

```rust
pub fn create_token_mint(
    ctx: Context<CreateTokenMint>,
    name: String,
    symbol: String,
    uri: String,
) -> Result<()>
```

**Accounts:**
- `metadata`: Metaplex metadata PDA
- `mint`: GRID token mint
- `authority` (Signer): Update authority
- `metadata_program`: Metaplex Token Metadata program
- `payer`: Fee payer

**Logic:**
1. Create Metaplex metadata
2. Set token name, symbol, URI
3. Set token standard: Fungible

**CPI to Metaplex:**
```rust
CreateV1CpiBuilder::new(&ctx.accounts.metadata_program.to_account_info())
    .metadata(&ctx.accounts.metadata.to_account_info())
    .mint(&ctx.accounts.mint.to_account_info(), true)
    .authority(&ctx.accounts.authority.to_account_info())
    .payer(&ctx.accounts.payer.to_account_info())
    .update_authority(&ctx.accounts.authority.to_account_info(), true)
    .name(name)
    .symbol(symbol)
    .uri(uri)
    .seller_fee_basis_points(0)
    .decimals(9)
    .token_standard(TokenStandard::Fungible)
    .print_supply(PrintSupply::Zero)
    .invoke()?;
```

---

## Trading Program

**Location:** `gridtokenx-anchor/programs/trading/src/lib.rs`  
**Purpose:** Order book management, escrow, settlement

### Program ID
```
69dGpKu9a8EZiZ7orgfTH6CoGj9DeQHHkHBF2exSr8na
```

### Accounts

#### Market (PDA)

```rust
#[account]
pub struct Market {
    pub authority: Pubkey,              // Market authority
    pub active_orders: u64,             // Active order count
    pub total_volume: u64,              // Lifetime volume (kWh)
    pub total_trades: u64,              // Lifetime trade count
    pub created_at: i64,                // Creation timestamp
    pub clearing_enabled: u8,           // Clearing enabled flag
    pub market_fee_bps: u16,            // Market fee (basis points)
    pub min_price_per_kwh: u64,         // Minimum price
    pub max_price_per_kwh: u64,         // Maximum price
    pub num_shards: u8,                 // Number of shards
    pub batch_config: BatchConfig,      // Batch trading config
}
```

**PDA Seeds:**
```rust
[b"market"]
```

#### Order (PDA)

```rust
#[account]
pub struct Order {
    pub seller: Pubkey,                 // Seller wallet
    pub buyer: Pubkey,                  // Buyer wallet (set on match)
    pub order_id: u64,                  // Order ID
    pub amount: u64,                    // Energy amount (kWh)
    pub filled_amount: u64,             // Filled amount
    pub price_per_kwh: u64,             // Price per kWh
    pub order_type: u8,                 // Order type enum
    pub status: u8,                     // Order status enum
    pub created_at: i64,                // Creation timestamp
    pub expires_at: i64,                // Expiration timestamp
}
```

**PDA Seeds:**
```rust
[b"order", order_id.as_bytes()]
```

#### Escrow (PDA)

```rust
#[account]
pub struct Escrow {
    pub buyer: Pubkey,                  // Buyer wallet
    pub seller: Pubkey,                 // Seller wallet
    pub amount: u64,                    // Locked amount
    pub price: u64,                     // Price per kWh
    pub status: u8,                     // Escrow status
    pub created_at: i64,                // Creation timestamp
}
```

**PDA Seeds:**
```rust
[b"escrow", order_id.as_bytes()]
```

### Instructions

#### Create Sell Order

```rust
pub fn create_sell_order(
    ctx: Context<CreateSellOrderContext>,
    order_id_val: u64,
    energy_amount: u64,
    price_per_kwh: u64,
) -> Result<()>
```

**Accounts:**
- `order` (PDA): `[b"order", order_id.as_bytes()]`
- `seller` (Signer): Seller wallet
- `zone_market`: Zone market account
- `governance_config`: Governance config (check operational status)

**Logic:**
1. Validate governance status (not in maintenance)
2. Validate energy amount > 0
3. Validate price within limits
4. Check ERC certificate (if applicable)
5. Create Order PDA
6. Emit `SellOrderCreated` event

**Event:**
```rust
pub struct SellOrderCreated {
    pub seller: Pubkey,
    pub order_id: Pubkey,
    pub amount: u64,
    pub price_per_kwh: u64,
    pub timestamp: i64,
}
```

---

#### Lock to Escrow

```rust
pub fn lock_to_escrow(
    ctx: Context<LockToEscrow>,
    amount: u64,
) -> Result<()>
```

**Accounts:**
- `escrow` (PDA): `[b"escrow", order_id.as_bytes()]`
- `buyer_ata`: Buyer's currency token account
- `escrow_ata`: Escrow token account
- `buyer_authority` (Signer): Buyer
- `token_program`: SPL Token program

**Logic:**
1. Transfer currency tokens from buyer to escrow
2. Update Escrow state
3. Emit `EscrowLocked` event

**CPI:**
```rust
let cpi_accounts = token_interface::TransferChecked {
    from: ctx.accounts.buyer_ata.to_account_info(),
    to: ctx.accounts.escrow_ata.to_account_info(),
    authority: ctx.accounts.buyer_authority.to_account_info(),
};

let cpi_ctx = CpiContext::new(token_program, cpi_accounts);
token_interface::transfer_checked(cpi_ctx, amount, decimals)?;
```

---

#### Release Escrow

```rust
pub fn release_escrow(
    ctx: Context<ReleaseEscrow>,
    amount: u64,
) -> Result<()>
```

**Accounts:**
- `escrow` (PDA): `[b"escrow", order_id.as_bytes()]`
- `escrow_ata`: Escrow token account
- `seller_ata`: Seller's currency token account
- `escrow_authority` (Signer): Gateway authority
- `token_program`: SPL Token program

**Logic:**
1. Transfer currency tokens from escrow to seller
2. Close escrow account
3. Emit `EscrowReleased` event

---

## Cross-Program Interactions

### Registry ↔ Energy Token

```rust
// Registry program mints GRID tokens via CPI to Energy Token program
let cpi_accounts = MintTo {
    token_info: token_info_account,
    mint: grid_token_mint,
    destination: user_ata,
    authority: registry_pda,  // PDA signing
    token_program: token_program,
};

let seeds = &[b"registry".as_ref(), &[ctx.bumps.registry]];
let signer = &[&seeds[..]];

let cpi_ctx = CpiContext::new_with_signer(
    energy_token_program,
    cpi_accounts,
    signer
);
mint_to_wallet(cpi_ctx, airdrop_amount)?;
```

### Trading ↔ Energy Token

```rust
// Trading program transfers energy tokens via CPI
let cpi_accounts = TransferChecked {
    from: seller_energy_ata,
    to: buyer_energy_ata,
    authority: seller_authority,
    token_program: token_program,
};

let cpi_ctx = CpiContext::new(token_program, cpi_accounts);
token_interface::transfer_checked(cpi_ctx, energy_amount, decimals)?;
```

### API Gateway → All Programs

```rust
// API Gateway sends transactions to all programs
// Example: Register meter on-chain

// 1. Build instruction for Registry program
let instruction = Instruction {
    program_id: registry_program_id,
    accounts: vec![
        AccountMeta::new(registry_pda, false),
        AccountMeta::new(meter_account_pda, false),
        AccountMeta::new_readonly(oracle_authority, true),
    ],
    data: [
        discriminator,  // sha256("global:update_meter_reading")[:8]
        energy_generated.to_le_bytes(),
        energy_consumed.to_le_bytes(),
        reading_timestamp.to_le_bytes(),
    ].concat(),
};

// 2. Build and send transaction
let tx = Transaction::new_signed_with_payer(
    &[instruction],
    Some(&payer.pubkey()),
    &[&payer],
    recent_blockhash,
);

client.send_and_confirm_transaction(&tx)?;
```

---

## Error Codes

### Registry Program

| Code | Name | Message |
|------|------|---------|
| 6000 | `UnauthorizedAuthority` | Unauthorized authority |
| 6001 | `InvalidShardId` | Invalid shard ID |
| 6002 | `MathOverflow` | Math overflow |
| 6003 | `UserAlreadyRegistered` | User already registered |
| 6004 | `MeterAlreadyRegistered` | Meter already registered |

### Energy Token Program

| Code | Name | Message |
|------|------|---------|
| 6000 | `UnauthorizedAuthority` | Unauthorized authority |
| 6001 | `InvalidAmount` | Invalid amount |
| 6002 | `InsufficientSupply` | Insufficient supply |

### Trading Program

| Code | Name | Message |
|------|------|---------|
| 6000 | `InvalidAmount` | Invalid amount |
| 6001 | `InvalidPrice` | Invalid price |
| 6002 | `MaintenanceMode` | Market in maintenance mode |
| 6003 | `PriceBelowMinimum` | Price below minimum |
| 6004 | `PriceAboveMaximum` | Price above maximum |
| 6005 | `InsufficientBalance` | Insufficient balance |
| 6006 | `OrderNotFound` | Order not found |
| 6007 | `InvalidErcCertificate` | Invalid ERC certificate |
| 6008 | `ErcExpired` | ERC expired |

---

## Events

All programs emit Anchor events for off-chain indexing:

```rust
// Registry events
#[event]
pub struct UserRegistered { ... }

#[event]
pub struct MeterRegistered { ... }

#[event]
pub struct MeterReadingUpdated { ... }

// Energy Token events
#[event]
pub struct TokensMinted { ... }

#[event]
pub struct TokensBurned { ... }

// Trading events
#[event]
pub struct SellOrderCreated { ... }

#[event]
pub struct BuyOrderCreated { ... }

#[event]
pub struct OrderMatched { ... }

#[event]
pub struct EscrowLocked { ... }

#[event]
pub struct EscrowReleased { ... }
```

---

## Testing

### Anchor Test Example

```typescript
// tests/registry.test.ts
import * as anchor from "@coral-xyz/anchor";
import { Registry } from "../target/types/registry";

describe("Registry Program", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.Registry as Program<Registry>;

  it("Initialize Registry", async () => {
    const [registryPda] = PublicKey.findProgramAddressSync(
      [Buffer.from("registry")],
      program.programId
    );

    await program.methods
      .initialize()
      .accounts({
        registry: registryPda,
        authority: provider.publicKey,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .rpc();

    const registry = await program.account.registry.fetch(registryPda);
    assert.ok(registry.authority.equals(provider.publicKey));
    assert.ok(registry.userCount === anchor.BN.ZERO);
  });

  it("Register User", async () => {
    const [userAccountPda] = PublicKey.findProgramAddressSync(
      [Buffer.from("user"), provider.publicKey.toBuffer()],
      program.programId
    );

    await program.methods
      .registerUser(
        { prosumer: {} },  // UserType
        137563000,         // lat_e7 (13.7563 * 10^7)
        1005018000,        // long_e7 (100.5018 * 10^7)
        new anchor.BN("0x8c2a90c000fffff"),  // H3 index
        0                  // shard_id
      )
      .accounts({
        userAccount: userAccountPda,
        user: provider.publicKey,
      })
      .rpc();

    const userAccount = await program.account.userAccount.fetch(userAccountPda);
    assert.ok(userAccount.user.equals(provider.publicKey));
    assert.ok(userAccount.latE7 === 137563000);
  });
});
```

---

## Related Documentation

- [User Registration Workflow](../guides/user-registration-workflow.md)
- [P2P Trading Flow](../guides/p2p-trading-flow.md)
- [Authentication & JWT Design](./authentication-jwt-design.md)
- [Data Flow: Simulator to Blockchain](../guides/data-flow-simulator-to-blockchain.md)

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-03-16 | Initial implementation with 5 programs |
