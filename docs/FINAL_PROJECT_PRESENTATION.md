# GridTokenX Platform
## Final Project Presentation
### Department of Engineering

---

# Agenda (20 Minutes)

| Time | Topic | Duration |
|------|-------|----------|
| 0:00 | Problem & Solution Overview | 1.5 min |
| 1:30 | System Architecture | 3 min |
| 4:30 | Technology Stack | 2.5 min |
| 7:00 | Database & API Design | 2 min |
| 9:00 | Smart Contract Implementation | 3 min |
| 12:00 | Live Demo | 6 min |
| 18:00 | Challenges & Lessons Learned | 1.5 min |
| 19:30 | Q&A | 0.5 min |

---

# 1. Problem & Solution Overview

## Problem Statement
- Traditional energy trading is centralized and inefficient
- Prosumers (solar panel owners) cannot easily sell excess energy
- Lack of transparency in energy transactions
- High transaction fees through intermediaries

## Solution: GridTokenX Platform
- **Decentralized P2P energy trading marketplace**
- **Blockchain-based** transparent transactions
- **Smart meter integration** for real-time energy data
- **Token-based** payment system (GridTokenX)

---

# 2. System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        GridTokenX Platform                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                 │
│  │  Explorer   │  │   Trading   │  │   Website   │  Frontend       │
│  │  (Next.js)  │  │  (Next.js)  │  │  (Next.js)  │  Layer          │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                 │
│         │                │                │                         │
│         └────────────────┼────────────────┘                         │
│                          │                                          │
│                          ▼                                          │
│              ┌───────────────────────┐                              │
│              │    API Gateway        │  Backend                     │
│              │    (Rust/Actix)       │  Layer                       │
│              └───────────┬───────────┘                              │
│                          │                                          │
│         ┌────────────────┼────────────────┐                         │
│         │                │                │                         │
│         ▼                ▼                ▼                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                 │
│  │ PostgreSQL  │  │   Solana    │  │Smart Meter  │  Data           │
│  │  Database   │  │ Blockchain  │  │ Simulator   │  Layer          │
│  └─────────────┘  └─────────────┘  └─────────────┘                 │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Microservices Overview

| Service | Technology | Purpose |
|---------|------------|---------|
| `gridtokenx-explorer` | Next.js | Blockchain explorer for transactions |
| `gridtokenx-trading` | Next.js | Energy trading marketplace |
| `gridtokenx-apigateway` | Rust/Actix | REST API backend |
| `gridtokenx-anchor` | Anchor/Solana | Smart contracts |
| `gridtokenx-smartmeter-simulator` | Python | IoT meter simulation |

---

# 3. Technology Stack

## Frontend
| Technology | Purpose |
|------------|---------|
| **Next.js 14** | React framework with App Router |
| **TypeScript** | Type-safe development |
| **Tailwind CSS** | Utility-first CSS framework |
| **shadcn/ui** | UI component library |
| **React Query** | Server state management |

## Backend
| Technology | Purpose |
|------------|---------|
| **Rust + Actix Web** | High-performance API server |
| **PostgreSQL** | Relational database |
| **SQLx** | Async database driver |
| **Redis** | Caching & session management |

## Blockchain
| Technology | Purpose |
|------------|---------|
| **Solana** | High-speed blockchain network |
| **Anchor Framework** | Smart contract development |
| **SPL Token** | Token standard for GridTokenX |

## DevOps
| Technology | Purpose |
|------------|---------|
| **Docker** | Containerization |
| **Docker Compose** | Multi-container orchestration |
| **GitHub Actions** | CI/CD pipeline |

---

# 4. Database & API Design

## Entity Relationship Diagram

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│    Users     │       │   Wallets    │       │   Meters     │
├──────────────┤       ├──────────────┤       ├──────────────┤
│ id (PK)      │──────▶│ id (PK)      │       │ id (PK)      │
│ email        │       │ user_id (FK) │       │ user_id (FK) │
│ password     │       │ public_key   │       │ meter_type   │
│ role         │       │ balance      │       │ location     │
│ created_at   │       │ created_at   │       │ status       │
└──────────────┘       └──────────────┘       └──────────────┘
        │                                            │
        │                                            │
        ▼                                            ▼
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│   Orders     │       │ Transactions │       │ MeterReadings│
├──────────────┤       ├──────────────┤       ├──────────────┤
│ id (PK)      │──────▶│ id (PK)      │       │ id (PK)      │
│ seller_id    │       │ order_id(FK) │       │ meter_id(FK) │
│ energy_kwh   │       │ buyer_id     │       │ energy_kwh   │
│ price_per_kwh│       │ seller_id    │       │ timestamp    │
│ status       │       │ tx_signature │       │ reading_type │
└──────────────┘       └──────────────┘       └──────────────┘
```

## Key API Endpoints

```
Authentication:
  POST   /api/auth/register     - User registration
  POST   /api/auth/login        - User login
  GET    /api/auth/me           - Get current user

Energy Trading:
  GET    /api/orders            - List energy orders
  POST   /api/orders            - Create sell order
  POST   /api/orders/:id/buy    - Execute purchase
  GET    /api/transactions      - Transaction history

Smart Meter:
  POST   /api/meters/reading    - Submit meter reading
  GET    /api/meters/:id/data   - Get meter data
  
Blockchain:
  POST   /api/mint              - Mint energy tokens
  GET    /api/balance/:address  - Get token balance
```

---

# 5. Smart Contract Implementation

## GridTokenX Token Contract (Anchor/Solana)

### Key Instructions

```rust
// Initialize the energy token mint
pub fn initialize_mint(ctx: Context<InitializeMint>) -> Result<()>

// Mint tokens based on energy production
pub fn mint_energy_tokens(
    ctx: Context<MintTokens>,
    energy_kwh: u64,
    meter_reading_id: String
) -> Result<()>

// Transfer tokens for energy purchase
pub fn transfer_tokens(
    ctx: Context<TransferTokens>,
    amount: u64
) -> Result<()>

// Burn tokens when energy is consumed
pub fn burn_tokens(
    ctx: Context<BurnTokens>,
    amount: u64
) -> Result<()>
```

## Token Flow Diagram

```
┌─────────────┐    Produce     ┌─────────────┐    Mint      ┌─────────────┐
│   Solar     │───────────────▶│   Smart     │─────────────▶│  GridTokenX │
│   Panel     │    Energy      │   Meter     │   Tokens     │   Wallet    │
└─────────────┘                └─────────────┘              └──────┬──────┘
                                                                   │
                                                                   │ List
                                                                   ▼
┌─────────────┐    Receive     ┌─────────────┐    Buy       ┌─────────────┐
│   Consumer  │◀───────────────│   Energy    │◀─────────────│ Marketplace │
│   Meter     │    Energy      │   Transfer  │   Order      │   Platform  │
└─────────────┘                └─────────────┘              └─────────────┘
```

## Smart Contract Security Features

- ✅ **Access Control** - Only authorized meters can mint
- ✅ **Double-spend Prevention** - Unique meter reading IDs
- ✅ **Rate Limiting** - Maximum mint per time period
- ✅ **Audit Trail** - All transactions on-chain

---

# 6. Live Demo

## Demo Flow (6 minutes)

### Step 1: User Registration & Login (1 min)
- Create new account
- Connect Solana wallet (Phantom)

### Step 2: Dashboard Overview (1 min)
- View wallet balance
- Check energy production stats

### Step 3: Energy Production & Minting (1.5 min)
- Smart meter submits reading
- Tokens automatically minted
- View transaction on explorer

### Step 4: Marketplace Trading (1.5 min)
- Browse available energy listings
- Execute a purchase transaction
- Confirm token transfer

### Step 5: Blockchain Verification (1 min)
- View transaction on Solana Explorer
- Verify token balances updated

---

# 7. Challenges & Lessons Learned

## Technical Challenges

| Challenge | Solution |
|-----------|----------|
| Solana transaction speed vs confirmation | Implemented optimistic updates with rollback |
| Smart meter data integrity | Digital signatures + hash verification |
| Real-time price updates | WebSocket connections + Redis pub/sub |
| Cross-service communication | API Gateway pattern with rate limiting |

## Performance Optimizations

- **Database indexing** on frequently queried columns
- **Connection pooling** for database connections
- **Response caching** with Redis
- **Lazy loading** for frontend components

## Security Measures

- JWT token authentication with refresh tokens
- Input validation and sanitization
- Rate limiting on all API endpoints
- Encrypted wallet private keys

---

# 8. Conclusion

## Achievements

✅ Built complete P2P energy trading platform  
✅ Integrated Solana blockchain for transparent transactions  
✅ Developed smart meter simulation system  
✅ Implemented secure token-based payment  

## Future Improvements

- 🔮 Real smart meter hardware integration
- 🔮 Mobile application (React Native)
- 🔮 AI-powered energy price prediction
- 🔮 Multi-chain support (Ethereum, Polygon)

---

# Q&A

## Thank You!

**Project Repository:** github.com/NakaSato/gridtokenx-platform-infa

### Contact
- Email: [your-email]
- GitHub: @NakaSato

---

# Appendix: Demo Commands

```bash
# Start all services
docker-compose up -d

# Run smart meter simulator
cd gridtokenx-smartmeter-simulator
python server.py

# Start API Gateway
cd gridtokenx-apigateway
cargo run

# Start Explorer
cd gridtokenx-explorer
pnpm dev

# Start Trading Platform
cd gridtokenx-trading
pnpm dev
```

## Test Accounts

| Role | Email | Wallet |
|------|-------|--------|
| Seller (Prosumer) | seller@test.com | [Phantom Wallet 1] |
| Buyer (Consumer) | buyer@test.com | [Phantom Wallet 2] |

---

# Backup: Key Code Snippets

## Smart Contract - Mint Energy Tokens

```rust
pub fn mint_energy_tokens(
    ctx: Context<MintTokens>,
    energy_kwh: u64,
    meter_reading_id: String,
) -> Result<()> {
    // Validate meter authorization
    require!(
        ctx.accounts.meter.is_authorized,
        ErrorCode::UnauthorizedMeter
    );
    
    // Calculate token amount (1 kWh = 1 token)
    let token_amount = energy_kwh * DECIMALS;
    
    // Mint tokens to user wallet
    token::mint_to(
        ctx.accounts.mint_to_context(),
        token_amount,
    )?;
    
    // Emit event for tracking
    emit!(EnergyMinted {
        meter: ctx.accounts.meter.key(),
        amount: token_amount,
        reading_id: meter_reading_id,
    });
    
    Ok(())
}
```

## API Gateway - Order Matching

```rust
async fn match_order(
    order_id: Uuid,
    buyer_id: Uuid,
    pool: &PgPool,
) -> Result<Transaction, ApiError> {
    let order = get_order(order_id, pool).await?;
    
    // Verify order is available
    if order.status != OrderStatus::Open {
        return Err(ApiError::OrderNotAvailable);
    }
    
    // Execute blockchain transfer
    let tx_sig = transfer_tokens(
        &order.seller_wallet,
        &buyer.wallet,
        order.token_amount,
    ).await?;
    
    // Update order status
    update_order_status(order_id, OrderStatus::Completed, pool).await?;
    
    // Create transaction record
    create_transaction(order, buyer_id, tx_sig, pool).await
}
```
