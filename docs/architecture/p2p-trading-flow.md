# P2P Trading Flow: Orders, Matching & Settlement

**Version:** 1.0  
**Last Updated:** March 16, 2026  
**Authors:** GridTokenX Engineering Team

---

## Overview

This document describes the complete P2P (Peer-to-Peer) energy trading flow in the GridTokenX platform, from order creation through matching to on-chain settlement.

### Key Features

| Feature | Implementation | Benefit |
|---------|----------------|---------|
| **Order Book Model** | Limit orders with price-time priority | Fair and transparent pricing |
| **Sharded Matching** | Zone-based sharding for scalability | 1000+ orders/second throughput |
| **P2P Cost Calculation** | Dynamic wheeling charges + loss factors | Accurate grid cost allocation |
| **On-Chain Settlement** | Atomic escrow via Anchor smart contracts | Trustless execution |
| **Real-Time Updates** | WebSocket broadcasts for order status | Instant user feedback |

---

## Complete P2P Trading Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    P2P TRADING FLOW ARCHITECTURE                         │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│  PHASE 1: ORDER CREATION                                                 │
│  Endpoint: POST /api/v1/trading/orders                                   │
│  Location: gridtokenx-api/src/api/handlers/trading_hdl/orders/    │
└──────────────────────────────────────────────────────────────────────────┘

    ┌──────────────────────────────────────────────────────────────────┐
    │  1.1 User Submits Trading Order                                  │
    │      Frontend: Trading UI / Dashboard                            │
    │      Auth: Bearer Token (JWT)                                    │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Request Headers:
       │ Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
       │
       │ Request Body:
       │ {
       │   "side": "sell",                    // or "buy"
       │   "order_type": "limit",             // or "market"
       │   "energy_amount": 10.5,             // kWh
       │   "price_per_kwh": 3.8,              // THB/kWh
       │   "zone_id": 1,                      // Grid zone
       │   "meter_id": "meter-uuid",          // Source/destination meter
       │   "expiry_time": "2026-03-17T00:00:00Z",
       │   "signature": "hmac-sha256-hash",   // Order signature
       │   "timestamp": 1710600600000         // Order timestamp (ms)
       │ }
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.2 Validate Order Signature (HMAC-SHA256)                      │
    │      File: create.rs → verify_signature()                        │
    │      Latency: < 5ms                                              │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Signature Verification:
       │ 1. Reconstruct message: "{side}:{amount}:{price}:{timestamp}"
       │ 2. Compute HMAC-SHA256 using system encryption_secret
       │ 3. Compare with provided signature
       │ 4. Verify timestamp within 5-minute window
       │
       │ Purpose: Prevents order tampering and replay attacks
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.3 Validate Order Parameters                                   │
    │      File: create.rs → create_order()                            │
    │      Latency: < 10ms                                             │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Validation Rules:
       │ ✓ energy_amount > 0
       │ ✓ price_per_kwh within market limits (min: 2.0, max: 5.0 THB)
       │ ✓ zone_id valid (0-10)
       │ ✓ expiry_time in future
       │ ✓ Signature valid (from step 1.2)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.4 Auto-Detect User Zone from Meter                            │
    │      File: create.rs → sqlx::query!()                            │
    │      Latency: 5-20ms                                             │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ SQL Query:
       │ SELECT zone_id FROM meter_registry 
       │ WHERE user_id = $1 
       │ ORDER BY created_at DESC LIMIT 1
       │
       │ If zone not provided in request:
       │ - Use meter's zone_id
       │ - If no meter found → Default to zone 0 (unknown)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.5 Create Order via Market Clearing Service                    │
    │      File: create.rs → market_clearing.create_order()            │
    │      Latency: 50-200ms                                           │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ MarketClearingService handles:
       │ 1. Check user balance (energy for sell, funds for buy)
       │ 2. Lock funds/energy (escrow in database)
       │ 3. Generate order ID (UUID v4)
       │ 4. Insert order into trading_orders table
       │ 5. Add to in-memory order book (sharded by zone)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.6 Insert Order into Database                                  │
    │      File: clearing.rs → sqlx::query!(INSERT INTO trading_orders)│
    │      Latency: 10-30ms                                            │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ SQL Insert:
       │ INSERT INTO trading_orders (
       │   id, user_id, side, order_type, energy_amount,
       │   price_per_kwh, zone_id, meter_id, status,
       │   filled_amount, locked_amount, expiry_time,
       │   created_at, updated_at
       │ ) VALUES (
       │   $1, $2, 'sell', 'limit', $3, $4, $5, $6, 'pending',
       │   0, $7, $8, NOW(), NOW()
       │ )
       │
       │ For SELL orders:
       │ - locked_amount = energy_amount (lock energy tokens)
       │
       │ For BUY orders:
       │ - locked_amount = energy_amount * price_per_kwh (lock currency)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.7 Add to In-Memory Order Book (Sharded)                       │
    │      File: matching.rs → buy_orders.insert() / sell_orders.insert() │
    │      Latency: < 1ms                                              │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Sharding Strategy:
       │ - Orders distributed across N shards based on zone_id
       │ - shard_id = zone_id % num_shards
       │ - Each shard has separate buy/sell order books
       │
       │ Data Structure:
       │ buy_orders:  DashMap<Uuid, TradingOrderDb>  // Sorted by price (desc), time (asc)
       │ sell_orders: DashMap<Uuid, TradingOrderDb>  // Sorted by price (asc), time (asc)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.8 Trigger Matching Engine                                     │
    │      File: mod.rs → trigger_matching()                           │
    │      Latency: 10-100ms (depends on order book depth)             │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Matching Triggered:
       │ - For LIMIT orders: Check if price crosses spread
       │ - For MARKET orders: Match immediately at best price
       │
       │ Matching Algorithm:
       │ 1. Price-Time Priority:
       │    - Best price gets priority
       │    - Same price → Earlier order gets priority
       │ 2. Match SELL order with BUY orders (and vice versa)
       │ 3. Calculate match quantity = min(sell_qty, buy_qty)
       │ 4. Calculate match price = (sell_price + buy_price) / 2
       │    (Mid-price mechanism for fairness)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  1.9 Return Order Creation Response                              │
    │      File: create.rs → Ok(Json(CreateOrderResponse))             │
    │      Total Latency: ~100-300ms                                   │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ HTTP 200 Response:
       │ {
       │   "success": true,
       │   "message": "Order created successfully",
       │   "order": {
       │     "id": "order-uuid",
       │     "user_id": "user-uuid",
       │     "side": "sell",
       │     "order_type": "limit",
       │     "energy_amount": 10.5,
       │     "price_per_kwh": 3.8,
       │     "filled_amount": 0.0,
       │     "status": "active",
       │     "zone_id": 1,
       │     "created_at": "2026-03-16T14:30:00Z"
       │   }
       │ }
       │
       │ ✅ ORDER CREATED - Now active in order book
       │
       ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  PHASE 2: ORDER MATCHING                                                 │
│  Location: gridtokenx-api/src/domain/trading/engine/              │
└──────────────────────────────────────────────────────────────────────────┘

    ┌──────────────────────────────────────────────────────────────────┐
    │  2.1 Matching Engine Scans Order Book                            │
    │      File: matching.rs → match_orders()                          │
    │      Runs: Every 1 second (configurable) or on new order         │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ For each SELL order:
       │ 1. Find matching BUY orders where:
       │    - buy_price >= sell_price
       │    - same zone_id (or adjacent zones)
       │    - status = 'active'
       │    - not expired
       │ 2. Sort by: price (desc), timestamp (asc)
       │ 3. Iterate through sorted BUY orders
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  2.2 Calculate Match Details                                     │
    │      File: matching.rs → calculate_match()                       │
    │      Latency: < 5ms per match                                    │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Match Calculation:
       │ match_quantity = min(sell_remaining, buy_remaining)
       │ match_price = (sell_price + buy_price) / 2  // Mid-price
       │
       │ Example:
       │ - SELL: 10 kWh @ 3.8 THB
       │ - BUY:  8 kWh @ 4.0 THB
       │ → Match: 8 kWh @ 3.9 THB (mid-price)
       │ → SELL remaining: 2 kWh (still in order book)
       │ → BUY filled: 100% (order complete)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  2.3 Calculate P2P Transaction Costs                             │
    │      File: p2p.rs → calculate_p2p_cost()                         │
    │      Latency: 50-200ms (may call simulator)                      │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Cost Components:
       │ 1. Energy Cost = match_quantity * match_price
       │ 2. Wheeling Charge = distance_km * wheeling_rate * quantity
       │ 3. Loss Cost = energy_cost * loss_factor
       │ 4. Total Cost = energy_cost + wheeling_charge + loss_cost
       │
       │ Loss Allocation:
       │ - Socialized model: Split 50/50 between buyer and seller
       │ - Loss factor increases with zone distance
       │
       │ Example Breakdown:
       │ {
       │   "energy_cost": 31.2,        // 8 kWh * 3.9 THB
       │   "wheeling_charge": 0.48,    // 2 zones * 0.03 THB/kWh * 8 kWh
       │   "loss_cost": 0.31,          // 1% loss factor * 31.2 THB
       │   "total_cost": 31.99,
       │   "effective_energy": 7.92,   // 8 kWh * (1 - 0.01 loss)
       │   "loss_allocation": "Split (50/50)"
       │ }
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  2.4 Create Match Record                                         │
    │      File: clearing.rs → sqlx::query!(INSERT INTO order_matches) │
    │      Latency: 10-30ms                                            │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ SQL Insert:
       │ INSERT INTO order_matches (
       │   id, buy_order_id, sell_order_id,
       │   matched_quantity, match_price,
       │   total_value, zone_id, status,
       │   created_at
       │ ) VALUES (
       │   $1, $2, $3, $4, $5, $6, $7, 'pending', NOW()
       │ )
       │
       │ Match Record:
       │ - Links buy and sell orders
       │ - Stores matched quantity and price
       │ - Status: 'pending' → 'settling' → 'completed'
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  2.5 Update Order Status                                         │
    │      File: clearing.rs → sqlx::query!(UPDATE trading_orders)     │
    │      Latency: 10-30ms                                            │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ SQL Updates:
       │ -- Update SELL order
       │ UPDATE trading_orders
       │ SET filled_amount = filled_amount + $1,
       │     status = CASE 
       │       WHEN filled_amount + $1 >= energy_amount THEN 'filled'
       │       ELSE 'partially_filled'
       │     END,
       │     updated_at = NOW()
       │ WHERE id = $2
       │
       │ -- Update BUY order (similar)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  2.6 Broadcast WebSocket Update                                  │
    │      File: broadcaster.rs → broadcast_p2p_order_update()         │
    │      Latency: < 10ms                                             │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ WebSocket Message:
       │ {
       │   "type": "order_matched",
       │   "data": {
       │     "order_id": "order-uuid",
       │     "match_id": "match-uuid",
       │     "matched_quantity": 8.0,
       │     "match_price": 3.9,
       │     "total_value": 31.2,
       │     "status": "pending_settlement",
       │     "counterparty_zone": 2
       │   }
       │ }
       │
       │ Recipients:
       │ - Both buyer and seller receive update
       │ - Trading UI shows real-time match status
       │
       ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  PHASE 3: ON-CHAIN SETTLEMENT                                            │
│  Location: gridtokenx-api/src/services/settlement.rs              │
│  Smart Contracts: gridtokenx-anchor/programs/trading/                    │
└──────────────────────────────────────────────────────────────────────────┘

    ┌──────────────────────────────────────────────────────────────────┐
    │  3.1 Settlement Service Processes Match                          │
    │      File: settlement.rs → process_settlement()                  │
    │      Latency: 200-500ms                                          │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Settlement Triggered:
       │ - Automatically after match creation
       │ - Batch processing every 30 seconds (optimization)
       │
       │ Pre-Settlement Checks:
       │ ✓ Both orders still active
       │ ✓ Locked funds/energy available
       │ ✓ No disputes or cancellations
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  3.2 Create Escrow PDA (Program Derived Address)                 │
    │      File: settlement.rs → derive_escrow_pda()                   │
    │      Latency: < 5ms                                              │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ PDA Derivation:
       │ escrow_pda = find_program_address(
       │   [b"escrow", order_id.as_bytes()],
       │   &trading_program_id
       │ )
       │
       │ Purpose:
       │ - Holds buyer's funds during settlement
       │ - Ensures atomic swap (payment ↔ energy tokens)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  3.3 Lock Buyer's Funds to Escrow                                │
    │      File: settlement.rs → lock_tokens_to_escrow()               │
    │      Latency: 100-300ms (Solana transaction)                     │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Solana Transaction #1:
       │ ┌───────────────────────────────────────────────────────────┐
       │ │ Program: Trading (5yakTtiNHXHonCPqkwh1M22jujqugCJhEkYaHAoaB6pG) │
       │ │ Instruction: lock_to_escrow                               │
       │ │                                                           │
       │ │ Accounts:                                                 │
       │ │ - buyer_ata: Buyer's currency token account               │
       │ │ - escrow_ata: Escrow token account (PDA)                  │
       │ │ - buyer_authority: [SIGNER]                               │
       │ │ - token_program: TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ys626dR4OD7 │
       │ │                                                           │
       │ │ Data:                                                     │
       │ │ - amount: 31200000000 (31.2 THB * 10^9)                   │
       │ └───────────────────────────────────────────────────────────┘
       │
       │ Anchor Program Logic:
       │ 1. Transfer currency tokens from buyer to escrow
       │ 2. Update EscrowAccount state
       │ 3. Emit event: EscrowLocked
       │
       │ Transaction Signature: 7AbCdEf... (example)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  3.4 Transfer Energy Tokens to Buyer                             │
    │      File: settlement.rs → transfer_energy_tokens()              │
    │      Latency: 100-300ms (Solana transaction)                     │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Solana Transaction #2:
       │ ┌───────────────────────────────────────────────────────────┐
       │ │ Program: Energy Token (ExZKhghptUk675rjxgHPjJZjczgWWRRwzUTQnqjPTLno) │
       │ │ Instruction: transfer                                     │
       │ │                                                           │
       │ │ Accounts:                                                 │
       │ │ - seller_energy_ata: Seller's energy token account        │
       │ │ - buyer_energy_ata: Buyer's energy token account          │
       │ │ - seller_authority: [SIGNER]                              │
       │ │ - token_program: TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ys626dR4OD7 │
       │ │                                                           │
       │ │ Data:                                                     │
       │ │ - amount: 8000000000 (8 kWh * 10^9)                       │
       │ └───────────────────────────────────────────────────────────┘
       │
       │ Anchor Program Logic:
       │ 1. Transfer energy tokens from seller to buyer
       │ 2. Update token balances
       │ 3. Emit event: EnergyTransferred
       │
       │ Transaction Signature: 8GhIjKl... (example)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  3.5 Release Escrow to Seller                                    │
    │      File: settlement.rs → release_escrow_to_seller()            │
    │      Latency: 100-300ms (Solana transaction)                     │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Solana Transaction #3:
       │ ┌───────────────────────────────────────────────────────────┐
       │ │ Program: Trading (5yakTtiNHXHonCPqkwh1M22jujqugCJhEkYaHAoaB6pG) │
       │ │ Instruction: release_escrow                               │
       │ │                                                           │
       │ │ Accounts:                                                 │
       │ │ - escrow_ata: Escrow token account (PDA)                  │
       │ │ - seller_ata: Seller's currency token account             │
       │ │ - escrow_authority: [SIGNER] (Gateway authority)          │
       │ │ - token_program: TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ys626dR4OD7 │
       │ │                                                           │
       │ │ Data:                                                     │
       │ │ - amount: 31200000000 (31.2 THB * 10^9)                   │
       │ └───────────────────────────────────────────────────────────┘
       │
       │ Anchor Program Logic:
       │ 1. Release currency tokens from escrow to seller
       │ 2. Close escrow account
       │ 3. Emit event: EscrowReleased
       │
       │ Transaction Signature: 9MnOpQr... (example)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  3.6 Update Database (Settlement Complete)                       │
    │      File: settlement.rs → sqlx::query!(UPDATE order_matches)    │
    │      Latency: 10-30ms                                            │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ SQL Updates:
       │ -- Update match record
       │ UPDATE order_matches
       │ SET status = 'completed',
       │     settlement_tx_signature = '7AbCdEf...',
       │     settled_at = NOW()
       │ WHERE id = $1
       │
       │ -- Update orders
       │ UPDATE trading_orders
       │ SET status = 'filled',
       │     locked_amount = 0,
       │     updated_at = NOW()
       │ WHERE id IN ($2, $3)
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  3.7 Broadcast Settlement Complete                               │
    │      File: broadcaster.rs → broadcast_settlement_complete()      │
    │      Latency: < 10ms                                             │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ WebSocket Message:
       │ {
       │   "type": "settlement_complete",
       │   "data": {
       │     "match_id": "match-uuid",
       │     "status": "completed",
       │     "settlement_signature": "7AbCdEf...",
       │     "buyer_received_energy": 8.0,
       │     "seller_received_payment": 31.2,
       │     "settled_at": "2026-03-16T14:31:00Z"
       │   }
       │ }
       │
       │ ✅ SETTLEMENT COMPLETE - Trade finalized on-chain
       │
       ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  PHASE 4: POST-SETTLEMENT                                                │
│  Location: gridtokenx-api/src/domain/trading/                     │
└──────────────────────────────────────────────────────────────────────────┘

    ┌──────────────────────────────────────────────────────────────────┐
    │  4.1 Update User Balances                                        │
    │      File: clearing.rs → sqlx::query!(UPDATE users)              │
    │      Latency: 10-30ms                                            │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ SQL Updates:
       │ -- Buyer: Deduct currency, add energy tokens
       │ UPDATE users
       │ SET balance = balance - 31.2,
       │     energy_balance = energy_balance + 8.0
       │ WHERE id = $1
       │
       │ -- Seller: Add currency, deduct energy tokens
       │ UPDATE users
       │ SET balance = balance + 31.2,
       │     energy_balance = energy_balance - 8.0
       │ WHERE id = $2
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  4.2 Record Trade History                                        │
    │      File: clearing.rs → sqlx::query!(INSERT INTO trade_history) │
    │      Latency: 10-30ms                                            │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ SQL Insert:
       │ INSERT INTO trade_history (
       │   id, buyer_id, seller_id, match_id,
       │   energy_amount, price_per_kwh, total_value,
       │   zone_id, settlement_signature, created_at
       │ ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
       │
       │ Purpose:
       │ - Audit trail for regulatory compliance
       │ - Analytics and reporting
       │ - Tax calculation
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  4.3 Send Notification                                           │
    │      File: notification.rs → send_trade_confirmation()           │
    │      Latency: < 10ms (async)                                     │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Email/SMS Notification:
       │ Subject: Trade Confirmation - 8 kWh @ 3.9 THB
       │
       │ Body:
       │ Your energy trade has been completed:
       │ - Energy: 8.0 kWh
       │ - Price: 3.9 THB/kWh
       │ - Total: 31.2 THB
       │ - Settlement: 7AbCdEf...
       │
       ▼
    ┌──────────────────────────────────────────────────────────────────┐
    │  4.4 Update Market Data                                          │
    │      File: market_data.rs → update_market_stats()                │
    │      Latency: < 10ms                                             │
    └──────────────────────────────────────────────────────────────────┘
       │
       │ Updates:
       │ - Last traded price: 3.9 THB/kWh
       │ - 24h volume: +8 kWh
       │ - Price index calculation
       │
       │ Used for:
       │ - Market data API endpoints
       │ - Price charts and analytics
       │ - Reference price for future orders
       │
       └─── ✅ COMPLETE P2P TRADING FLOW
```

---

## Timeline Summary

### Phase 1: Order Creation

| Time | Event | Latency |
|------|-------|---------|
| **T+0ms** | User submits order | - |
| **T+5ms** | Signature verified | ~5ms |
| **T+15ms** | Order parameters validated | ~10ms |
| **T+35ms** | User zone detected | ~20ms |
| **T+235ms** | Order created in database | ~200ms |
| **T+236ms** | Added to in-memory order book | ~1ms |
| **T+336ms** | Matching engine triggered | ~100ms |
| **T+350ms** | ✅ **Order created** | ~350ms total |

### Phase 2: Order Matching

| Time | Event | Latency |
|------|-------|---------|
| **T+0ms** | Matching engine scans order book | - |
| **T+50ms** | Match found (price-time priority) | ~50ms |
| **T+55ms** | Match details calculated | ~5ms |
| **T+255ms** | P2P costs calculated | ~200ms |
| **T+285ms** | Match record created | ~30ms |
| **T+315ms** | Order status updated | ~30ms |
| **T+325ms** | WebSocket broadcast | ~10ms |
| **T+350ms** | ✅ **Match complete** | ~350ms total |

### Phase 3: On-Chain Settlement

| Time | Event | Latency |
|------|-------|---------|
| **T+0ms** | Settlement service triggered | - |
| **T+5ms** | Escrow PDA derived | ~5ms |
| **T+305ms** | Buyer funds locked to escrow | ~300ms |
| **T+605ms** | Energy tokens transferred | ~300ms |
| **T+905ms** | Escrow released to seller | ~300ms |
| **T+935ms** | Database updated | ~30ms |
| **T+945ms** | Settlement broadcast | ~10ms |
| **T+950ms** | ✅ **Settlement complete** | ~950ms total |

**Total Trading Flow:** ~1.6 seconds (order → settlement)

---

## Smart Contract Architecture

### Trading Program Instructions

| Instruction | Purpose | Accounts |
|-------------|---------|----------|
| `create_order` | Create order on-chain | Order PDA, buyer/seller ATA |
| `lock_to_escrow` | Lock buyer funds | Escrow PDA, buyer ATA |
| `release_escrow` | Release to seller | Escrow PDA, seller ATA |
| `cancel_order` | Cancel and refund | Order PDA, buyer ATA |
| `settle_match` | Atomic settlement | Escrow, both ATAs |

### Program IDs

| Program | ID | Purpose |
|---------|-----|---------|
| **Trading** | `5yakTtiNHXHonCPqkwh1M22jujqugCJhEkYaHAoaB6pG` | Order book, escrow, settlement |
| **Energy Token** | `ExZKhghptUk675rjxgHPjJZjczgWWRRwzUTQnqjPTLno` | GRID token (energy-backed) |
| **Registry** | `DVoD5K5YRuXXF54a3b6r282jRD8RmtVHGfpw55DHFVDe` | Meter registration |

---

## Database Schema

### Trading Orders Table

```sql
CREATE TABLE trading_orders (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),
    side VARCHAR(10) NOT NULL,  -- 'buy' or 'sell'
    order_type VARCHAR(20) NOT NULL,  -- 'limit' or 'market'
    energy_amount DECIMAL(20, 9) NOT NULL,
    price_per_kwh DECIMAL(10, 4),
    filled_amount DECIMAL(20, 9) DEFAULT 0,
    locked_amount DECIMAL(20, 9) DEFAULT 0,
    zone_id INTEGER REFERENCES zones(id),
    meter_id UUID REFERENCES meters(id),
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    expiry_time TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    filled_at TIMESTAMPTZ,
    refund_tx_signature VARCHAR(255),
    order_pda VARCHAR(255),  -- On-chain PDA
    session_token VARCHAR(255)
);

CREATE INDEX idx_orders_user ON trading_orders(user_id);
CREATE INDEX idx_orders_status ON trading_orders(status);
CREATE INDEX idx_orders_zone ON trading_orders(zone_id);
CREATE INDEX idx_orders_side_price ON trading_orders(side, price_per_kwh);
```

### Order Matches Table

```sql
CREATE TABLE order_matches (
    id UUID PRIMARY KEY,
    buy_order_id UUID NOT NULL REFERENCES trading_orders(id),
    sell_order_id UUID NOT NULL REFERENCES trading_orders(id),
    matched_quantity DECIMAL(20, 9) NOT NULL,
    match_price DECIMAL(10, 4) NOT NULL,
    total_value DECIMAL(20, 9) NOT NULL,
    zone_id INTEGER,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    settlement_tx_signature VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    settled_at TIMESTAMPTZ
);

CREATE INDEX idx_matches_buy ON order_matches(buy_order_id);
CREATE INDEX idx_matches_sell ON order_matches(sell_order_id);
CREATE INDEX idx_matches_status ON order_matches(status);
```

---

## Related Documentation

- [User Registration Workflow](./user-registration-workflow.md)
- [Data Flow: Simulator to Blockchain](./data-flow-simulator-to-blockchain.md)
- [Smart Contract Architecture](./smart-contract-architecture.md)
- [Authentication & JWT Design](./authentication-jwt-design.md)

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-03-16 | Initial implementation with sharded matching |
