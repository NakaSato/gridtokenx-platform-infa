# GridTokenX Smart Contract Architecture - 5 Programs

**Version:** 1.0  
**Last Updated:** 3 April 2026  
**Language:** Thai

---

## สารบัญ

1. [ภาพรวม Smart Contract Architecture](#1-ภาพรวม-smart-contract-architecture)
2. [5 Programs หลัก](#2-5-programs-หลัก)
3. [ความสัมพันธ์ระหว่าง Programs](#3-ความสัมพันธ์ระหว่าง-programs)
4. [Registry Program](#4-registry-program)
5. [Energy Token Program](#5-energy-token-program)
6. [Trading Program](#6-trading-program)
7. [Oracle Program](#7-oracle-program)
8. [Governance Program](#8-governance-program)
9. [Cross-Program Invocations (CPIs)](#9-cross-program-invocations-cpis)
10. [PDA Account Hierarchy](#10-pda-account-hierarchy)
11. [Transaction Flow Examples](#11-transaction-flow-examples)
12. [Program IDs](#12-program-ids)

---

## 1. ภาพรวม Smart Contract Architecture

GridTokenX สร้างขึ้นบน **Solana Private Proof-of-Authority (PoA)** โดยใช้ **Anchor Framework** ในการพัฒนา smart contracts ทั้ง 5 programs ที่ทำงานร่วมกันเป็นระบบนิเวศเดียว

```
┌─────────────────────────────────────────────────────────────────────┐
│                  GRIDTOKENX SMART CONTRACT ARCHITECTURE              │
└─────────────────────────────────────────────────────────────────────┘

                        ┌─────────────────────┐
                        │   GOVERNANCE        │
                        │   PROGRAM           │
                        │                     │
                        │ • ERC Certificates  │
                        │ • PoA Configuration │
                        │ • Voting            │
                        └──────────┬──────────┘
                                   │
                                   │ Validates ERC สำหรับ Trading
                                   ▼
┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│   REGISTRY          │     │    TRADING          │     │   ORACLE            │
│   PROGRAM           │     │    PROGRAM          │     │   PROGRAM           │
│                     │     │                     │     │                     │
│ • User Registration │     │ • Order Management  │     │ • Meter Data        │
│ • Meter Management  │────►│ • Order Matching    │◄────│ • Validation        │
│ • Reading Storage   │     │ • Settlement        │     │ • BFT Consensus     │
│ • Balance Settle    │     │ • Escrow Control    │     │ • Market Clearing   │
└──────────┬──────────┘     └──────────┬──────────┘     └─────────────────────┘
           │                           │
           │ CPI: Mint Request         │ CPI: Token Transfer
           ▼                           ▼
        ┌─────────────────────────────────────────────┐
        │              ENERGY TOKEN PROGRAM           │
        │                                             │
        │            • GRX Token Mint (1 kWh = 1 GRX)│
        │            • Token Transfers               │
        │            • Burn Operations               │
        │            • SPL Token-2022                │
        │                                             │
        │                   ใช้                       │
        │                    ▼                       │
        │         ┌─────────────────────┐           │
        │         │   SPL TOKEN         │           │
        │         │   PROGRAM           │           │
        │         │   (System)          │           │
        │         └─────────────────────┘           │
        └─────────────────────────────────────────────┘


Legend:
─────► CPI (Cross-Program Invocation) - การเรียกใช้ข้าม program
────── Data/State Dependency - การพึ่งพาข้อมูล/สถานะ
```

---

## 2. 5 Programs หลัก

| Program | หน้าที่ | Avg CU | Throughput | PDA Seeds |
|---------|---------|--------|------------|-----------|
| **Registry** | จัดการตัวตนผู้ใช้และมิเตอร์, เก็บข้อมูลการผลิต/ใช้พลังงาน | 6,000 | 19,350/sec | `["registry"]`, `["user", wallet]`, `["meter", meter_id]` |
| **Energy Token** | ออกและจัดการ GRX token (1 kWh = 1 GRX) | 18,000 | 6,665/sec | `["token_info_2022"]` |
| **Trading** | ตลาดซื้อขายพลังงาน P2P, จับคู่คำสั่ง, ชำระราคา | 12,000 | 8,000/sec | `["market"]`, `["order", user, counter]`, `["escrow", order_id]` |
| **Oracle** | รับและตรวจสอบข้อมูลจากมิเตอร์อัจฉริยะ | 8,000 | 15,000/sec | `["oracle_data"]`, `["oracle_authority"]`, `["backup_oracle", pubkey]` |
| **Governance** | ออกใบรับรอง REC, จัดการ PoA, voting | 6,200 | 18,460/sec | `["poa_config"]`, `["erc_certificate", cert_id]` |

---

## 3. ความสัมพันธ์ระหว่าง Programs

### 3.1 ภาพรวม Data Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    END-TO-END DATA FLOW                              │
└─────────────────────────────────────────────────────────────────────┘

Smart Meter (IoT)
       │
       │ 1. ส่งข้อมูลการผลิต/ใช้พลังงาน
       ▼
┌─────────────────┐
│  ORACLE         │  ตรวจสอบความถูกต้องของข้อมูลมิเตอร์
│  PROGRAM        │  - Range validation
│                 │  - Anomaly detection
│                 │  - Monotonic timestamps
└────────┬────────┘
         │ 2. Emit Event: MeterReadingSubmitted
         ▼
┌─────────────────┐
│  REGISTRY       │  คำนวณพลังงานสุทธิ (net generation)
│  PROGRAM        │  - total_production - total_consumption
│                 │  - ตรวจสอบ dual high-water marks
└────────┬────────┘
         │ 3. CPI: mint_tokens_direct
         ▼
┌─────────────────┐
│  ENERGY TOKEN   │  ออก GRX tokens (1 kWh = 1 GRX)
│  PROGRAM        │  - Mint to user wallet
│                 │  - Update total supply
└────────┬────────┘
         │ 4. ผู้ใช้มี GRX พร้อมซื้อขาย
         ▼
┌─────────────────┐
│  TRADING        │  สร้างคำสั่งซื้อขาย, จับคู่, ชำระราคา
│  PROGRAM        │  - Order book management
│                 │  - Atomic settlement
└────────┬────────┘
         │ 5. ตรวจสอบ ERC certificate (ถ้ามี)
         ▼
┌─────────────────┐
│  GOVERNANCE     │  ออกและตรวจสอบใบรับรอง REC
│  PROGRAM        │  - Verify unclaimed energy
│                 │  - Issue ERC certificate
└─────────────────┘
```

### 3.2 ความสัมพันธ์แบบคู่

| From Program | To Program | Interaction Type | Purpose |
|--------------|------------|------------------|---------|
| **Oracle** | **Registry** | Event-driven | ส่งข้อมูลที่ตรวจสอบแล้วเพื่อคำนวณยอดสุทธิ |
| **Registry** | **Energy Token** | CPI (Cross-Program Invocation) | Mint GRX tokens จากพลังงานที่ผลิตได้ |
| **Registry** | **Governance** | CPI | ตรวจสอบพลังงานที่ยังไม่ได้รับใบรับรอง REC |
| **Trading** | **Governance** | CPI | ตรวจสอบ ERC certificate ก่อนซื้อขาย |
| **Trading** | **Energy Token** | CPI | โอน GRX tokens ระหว่างผู้ซื้อและผู้ขาย |
| **Governance** | **Registry** | CPI | ยืนยัน dual high-water marks |

---

## 4. Registry Program

**Program ID:** `3aF9FmyFuGzg4i1TCyySLQM1zWK8UUQyFALxo2f236ye`  
**หน้าที่:** จัดการตัวตนผู้ใช้, มิเตอร์, และข้อมูลการผลิต/ใช้พลังงาน

### 4.1 PDA Accounts

#### Registry PDA
```rust
Seeds: ["registry"]

pub struct Registry {
    pub authority: Pubkey,              // ผู้ดูแลระบบ
    pub oracle_authority: Pubkey,       // Oracle ที่อนุญาต
    pub has_oracle_authority: u8,       // Flag: ตั้งค่า oracle แล้วหรือยัง
    pub user_count: u64,                // จำนวนผู้ใช้ทั้งหมด
    pub meter_count: u64,               // จำนวนมิเตอร์ทั้งหมด
    pub active_meter_count: u64,        // มิเตอร์ที่ใช้งานอยู่
}
```

#### UserAccount PDA
```rust
Seeds: ["user", user.key().as_ref()]

pub struct UserAccount {
    pub user: Pubkey,                   // Wallet address ของผู้ใช้
    pub user_type: UserType,            // Prosumer, Consumer, Prosumer2
    pub lat_e7: i32,                    // Latitude * 10^7
    pub long_e7: i32,                   // Longitude * 10^7
    pub h3_index: u64,                  // H3 geospatial index
    pub meter_count: u64,               // จำนวนมิเตอร์ที่เป็นเจ้าของ
    pub total_energy_generated: u64,    // การผลิตพลังงานสะสม (Wh)
    pub total_energy_consumed: u64,     // การใช้พลังงานสะสม (Wh)
    pub created_at: i64,                // เวลาสมัครสมาชิก
}
```

#### MeterAccount PDA (สำคัญ)
```rust
Seeds: ["meter", owner.key().as_ref(), meter_id.as_ref()]

pub struct MeterAccount {
    pub owner: Pubkey,                  // Wallet address ของเจ้าของ
    pub meter_id: [u8; 32],             // หมายเลขซีเรียลของมิเตอร์
    pub meter_type: MeterType,          // Residential, Commercial, Industrial
    pub location: [u8; 32],             // ตำแหน่ง
    pub latitude: Option<f64>,          // พิกัด GPS
    pub longitude: Option<f64>,         // พิกัด GPS
    pub is_verified: bool,              // ตรวจสอบแล้วโดยผู้ดูแล
    pub last_reading_generated: u64,    // การอ่านครั้งล่าสุด (ผลิต)
    pub last_reading_consumed: u64,     // การอ่านครั้งล่าสุด (ใช้)
    pub last_reading_timestamp: i64,    // เวลาการอ่านครั้งล่าสุด
    pub total_generated: u64,           // การผลิตสะสม
    pub total_consumed: u64,            // การใช้สะสม
    pub settled_net_generation: u64,    // ⭐ Mint GRX แล้วเท่าไร
    pub claimed_erc_generation: u64,    // ⭐ ออก REC แล้วเท่าไร
    pub created_at: i64,                // เวลาจดทะเบียนมิเตอร์
}
```

### 4.2 Dual High-Water Marks (สำคัญมาก)

```
┌─────────────────────────────────────────────────────────────────────┐
│              DUAL HIGH-WATER MARKS PREVENTION                        │
└─────────────────────────────────────────────────────────────────────┘

MeterAccount มี 2 ตัวแปรป้องกันการ claim ซ้ำ:

1. settled_net_generation  →  ติดตามว่า mint GRX tokens ไปแล้วเท่าไร
2. claimed_erc_generation  →  ติดตามว่าออก ERC certificates ไปแล้วเท่าไร

ตัวอย่าง:
┌─────────────────────────────────────────────────────────────────┐
│ total_generated = 100 kWh                                       │
│ total_consumed = 40 kWh                                         │
│ net_generation = 60 kWh                                         │
│                                                                 │
│ settled_net_generation = 30 kWh  (mint GRX ไปแล้ว 30 tokens)   │
│ claimed_erc_generation = 20 kWh  (ออก REC ไปแล้ว 20 certs)     │
│                                                                 │
│ พร้อม mint GRX ใหม่ = 60 - 30 = 30 kWh                         │
│ พร้อมออก REC ใหม่ = 60 - 20 = 40 kWh                           │
│                                                                 │
│ ⚠️  แต่ต้องไม่ claim ซ้ำจากพลังงานก้อนเดียวกัน!                │
└─────────────────────────────────────────────────────────────────┘
```

### 4.3 Instructions

| Instruction | Arguments | CU | Description |
|-------------|-----------|-----|-------------|
| `initialize` | - | ~5,000 | เริ่มต้น Registry |
| `register_user` | user_type, lat_e7, long_e7, h3_index, shard_id | ~5,500 | ลงทะเบียนผู้ใช้ + Airdrop 20 GRX |
| `register_meter` | meter_id, meter_type, location | ~6,200 | จดทะเบียนมิเตอร์ |
| `update_meter_reading` | energy_generated, energy_consumed, timestamp | ~3,500 | อัพเดทข้อมูลมิเตอร์ (Oracle only) |
| `settle_energy` | - | ~12,000 | คำนวณและ mint GRX tokens |
| `update_claimed_erc_generation` | amount | ~2,800 | อัพเดทยอด REC ที่ claim แล้ว |

---

## 5. Energy Token Program

**Program ID:** `8jTDw36yCQyYdr9hTtve5D5bFuQdaJ6f3WbdM4iGPHuq`  
**หน้าที่:** จัดการ GRX token (SPL Token-2022) - mint, burn, transfer

### 5.1 Token Specification

| Property | Value |
|----------|-------|
| **ชื่อ** | GridTokenX Energy Token |
| **สัญลักษณ์** | GRX |
| **มาตรฐาน** | SPL Token-2022 |
| **ทศนิยม** | 9 |
| **Supply** | Elastic (mint/burn ตามพลังงานจริง) |
| **Mint Authority** | PDA (seeds: `["token_info_2022"]`) |
| **Freeze Authority** | ไม่มี (โอนได้อิสระ) |
| **Burn Authority** | ผู้ถือ token + Energy Token Program |
| **REC Validators** | สูงสุด 10 validators (จัดการโดย governance) |

### 5.2 PDA Accounts

#### TokenInfo PDA
```rust
Seeds: ["token_info_2022"]

pub struct TokenInfo {
    pub authority: Pubkey,              // Program authority
    pub registry_authority: Pubkey,     // Registry program authority
    pub registry_program: Pubkey,       // Registry program ID
    pub mint: Pubkey,                   // GRX token mint account
    pub total_supply: u64,              // อุปทานทั้งหมด (sync เป็นระยะ)
    pub created_at: i64,                // เวลาสร้าง token
}
```

### 5.3 Instructions

| Instruction | Arguments | CU | Description |
|-------------|-----------|-----|-------------|
| `initialize_token` | registry_program_id, registry_authority | ~13,000 | เริ่มต้น Token program |
| `create_token_mint` | name, symbol, uri | ~45,000 | สร้าง Metaplex metadata |
| `mint_to_wallet` | amount | ~18,000 | Mint GRX ไปยัง wallet |
| `burn_tokens` | amount | ~14,000 | Burn tokens ออกจาก circulation |
| `transfer_tokens` | amount | ~15,200 | โอน tokens ระหว่าง wallets |
| `add_rec_validator` | validator_pubkey | ~2,800 | เพิ่มผู้ตรวจสอบ REC |

### 5.4 Token Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                        GRX TOKEN FLOW                               │
└─────────────────────────────────────────────────────────────────────┘

1. MINTING (การผลิต)
   ┌──────────────────────────────────────────────────────────────┐
   │ Smart Meter → Oracle → Registry → Energy Token → User Wallet│
   │                                                              │
   │ net_generation = total_production - total_consumption       │
   │ settleable = net_generation - settled_net_generation        │
   │ grx_minted = settleable × 10^9 (9 decimals)                │
   │                                                              │
   │ ตัวอย่าง: 15.5 kWh - 5.2 kWh = 10.3 kWh → 10.3 GRX        │
   └──────────────────────────────────────────────────────────────┘

2. TRADING (การซื้อขาย)
   ┌──────────────────────────────────────────────────────────────┐
   │ Seller Wallet → Escrow → Match → Buyer Wallet               │
   │                                                              │
   │ Atomic settlement: โอนพลังงาน ↔ โอนเงิน                     │
   └──────────────────────────────────────────────────────────────┘

3. BURNING (การเผา)
   ┌──────────────────────────────────────────────────────────────┐
   │ User Wallet → Burn Address (optional)                        │
   │                                                              │
   │ ลดอุปทาน, เพิ่มค่าของ token ที่เหลือ                         │
   └──────────────────────────────────────────────────────────────┘
```

---

## 6. Trading Program

**Program ID:** `GTuRUUwCfvmqW7knqQtzQLMCy61p4UKUrdT5ssVgZbat`  
**หน้าที่:** ตลาดซื้อขายพลังงาน P2P, จับคู่คำสั่ง, ชำระราคาแบบ atomic

### 6.1 PDA Accounts

#### Market PDA
```rust
Seeds: ["market"]

pub struct Market {
    pub authority: Pubkey,              // Market authority
    pub active_orders: u64,             // จำนวนคำสั่งที่เปิดอยู่
    pub total_volume: u64,              // ปริมาณซื้อขายสะสม (kWh)
    pub total_trades: u64,              // จำนวนการซื้อขายทั้งหมด
    pub created_at: i64,                // เวลาสร้างตลาด
    pub clearing_enabled: u8,           // เปิดใช้งาน clearing หรือไม่
    pub market_fee_bps: u16,            // ค่าธรรมเนียม (basis points)
    pub min_price_per_kwh: u64,         // ราคาต่ำสุดต่อ kWh
    pub max_price_per_kwh: u64,         // ราคาสูงสุดต่อ kWh
    pub num_shards: u8,                 // จำนวน shards
    pub batch_config: BatchConfig,      // การตั้งค่า batch trading
}
```

#### Order PDA
```rust
Seeds: ["order", user_pubkey, order_counter]

pub struct Order {
    pub seller: Pubkey,                 // Wallet ผู้ขาย
    pub buyer: Pubkey,                  // Wallet ผู้ซื้อ (set เมื่อจับคู่)
    pub order_id: u64,                  // หมายเลขคำสั่ง
    pub amount: u64,                    // ปริมาณพลังงาน (kWh)
    pub filled_amount: u64,             // ปริมาณที่จับคู่แล้ว
    pub price_per_kwh: u64,             // ราคาต่อ kWh
    pub order_type: u8,                 // ประเภทคำสั่ง (Bilateral/CDA)
    pub status: u8,                     // สถานะ (pending/active/filled/cancelled)
    pub created_at: i64,                // เวลาสร้างคำสั่ง
    pub expires_at: i64,                // เวลาหมดอายุ
}
```

#### Escrow PDA
```rust
Seeds: ["escrow", order_id]

pub struct Escrow {
    pub buyer: Pubkey,                  // Wallet ผู้ซื้อ
    pub seller: Pubkey,                 // Wallet ผู้ขาย
    pub amount: u64,                    // จำนวนเงินที่ lock ไว้
    pub price: u64,                     // ราคาต่อ kWh
    pub status: u8,                     // สถานะ escrow
    pub created_at: i64,                // เวลาสร้าง escrow
}
```

### 6.2 Instructions

| Instruction | Arguments | CU | Description |
|-------------|-----------|-----|-------------|
| `create_market` | authority, fee_config | ~8,500 | สร้างตลาดใหม่ |
| `create_buy_order` | amount, price_per_kwh, zone_id | ~7,200 | สร้างคำสั่งซื้อ |
| `create_sell_order` | amount, price_per_kwh, zone_id | ~7,500 | สร้างคำสั่งขาย |
| `match_orders` | buy_order_id, sell_order_id | ~15,000 | จับคู่คำสั่งซื้อ-ขาย |
| `execute_atomic_settlement` | match_details | ~28,000 | ชำระราคาแบบ atomic (6-way) |
| `lock_to_escrow` | amount | ~10,000 | Lock เงินเข้า escrow |
| `release_escrow` | amount | ~9,500 | ปลด lock เงินไปยังผู้ขาย |
| `update_price_history` | price | ~3,000 | อัพเดทประวัติราคา |

### 6.3 Trading Modalities

```
┌─────────────────────────────────────────────────────────────────────┐
│                    TRADING MODALITIES                                │
└─────────────────────────────────────────────────────────────────────┘

1. P2P Order Book (Continuous Double Auction)
   ┌──────────────────────────────────────────────────────────────┐
   │ - คำสั่งซื้อซื้อ/ขายจับคู่แบบ real-time                      │
   │ - Price-time priority: ราคาดีที่สุดได้ก่อน, เวลาเดียวกันตามลำดับ│
   │ - Mid-price mechanism: (buy_price + sell_price) / 2         │
   │                                                              │
   │ ตัวอย่าง:                                                    │
   │ SELL: 10 kWh @ 3.8 THB                                      │
   │ BUY:  8 kWh @ 4.0 THB                                       │
   │ → Match: 8 kWh @ 3.9 THB (mid-price)                       │
   └──────────────────────────────────────────────────────────────┘

2. Periodic Auction (Batch Clearing)
   ┌──────────────────────────────────────────────────────────────┐
   │ - รับคำสั่งในช่วงเวลา (เช่น 5 นาที)                         │
   │ - หา clearing price ที่ supply = demand                     │
   │ - ทุกคำสั่งที่จับคู่ได้ในราคานี้                            │
   │                                                              │
   │ ตัวอย่าง:                                                    │
   │ Supply: 200 GRX, Demand: 160 GRX                           │
   │ → P* = 3.4 THB, Q* = 130 GRX                               │
   └──────────────────────────────────────────────────────────────┘

3. AMM (Automated Market Maker)
   ┌──────────────────────────────────────────────────────────────┐
   │ - Constant product formula: x × y = k                       │
   │ - สภาพคล่องทันที ไม่ต้องรอจับคู่                            │
   │ - Fee: 0.3% ให้ liquidity providers                        │
   └──────────────────────────────────────────────────────────────┘

4. Confidential Trading (Future)
   ┌──────────────────────────────────────────────────────────────┐
   │ - ElGamal encryption สำหรับคำสั่งซื้อเป็นความลับ            │
   │ - Zero-knowledge proofs ยืนยันความถูกต้องโดยไม่เปิดเผยข้อมูล │
   └──────────────────────────────────────────────────────────────┘
```

### 6.4 Atomic Settlement Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                  ATOMIC SETTLEMENT (3 Transactions)                  │
└─────────────────────────────────────────────────────────────────────┘

Transaction #1: Lock Buyer's Funds
┌─────────────────────────────────────────────────────────────────┐
│ Program: Trading                                                 │
│ Instruction: lock_to_escrow                                     │
│                                                                  │
│ Accounts:                                                        │
│ - buyer_ata: บัญชีเงินของผู้ซื้อ                                 │
│ - escrow_ata: บัญชี escrow (PDA)                                │
│ - buyer_authority: [SIGNER]                                     │
│                                                                  │
│ Action: โอนเงิน 31.2 THB จากผู้ซื้อ → escrow                   │
└─────────────────────────────────────────────────────────────────┘

Transaction #2: Transfer Energy Tokens
┌─────────────────────────────────────────────────────────────────┐
│ Program: Energy Token                                            │
│ Instruction: transfer                                            │
│                                                                  │
│ Accounts:                                                        │
│ - seller_energy_ata: บัญชี GRX ของผู้ขาย                        │
│ - buyer_energy_ata: บัญชี GRX ของผู้ซื้อ                        │
│ - seller_authority: [SIGNER]                                    │
│                                                                  │
│ Action: โอน 8 kWh (8 GRX) จากผู้ขาย → ผู้ซื้อ                  │
└─────────────────────────────────────────────────────────────────┘

Transaction #3: Release Escrow to Seller
┌─────────────────────────────────────────────────────────────────┐
│ Program: Trading                                                 │
│ Instruction: release_escrow                                      │
│                                                                  │
│ Accounts:                                                        │
│ - escrow_ata: บัญชี escrow (PDA)                                │
│ - seller_ata: บัญชีเงินของผู้ขาย                                 │
│ - escrow_authority: [SIGNER] (Gateway authority)                │
│                                                                  │
│ Action: โอนเงิน 31.2 THB จาก escrow → ผู้ขาย                   │
└─────────────────────────────────────────────────────────────────┘

⭐ Atomic: ถ้า transaction ใด transaction หนึ่งล้มเหลว → ทั้งหมด rollback
```

---

## 7. Oracle Program

**Program ID:** `ACeKwdMK1sma3EPnxy7bvgC5yMwy8tg7ZUJvaogC9YfR`  
**หน้าที่:** รับและตรวจสอบข้อมูลจากมิเตอร์อัจฉริยะ, validate ก่อนส่งเข้า blockchain

### 7.1 PDA Accounts

#### OracleData PDA
```rust
Seeds: ["oracle_data"]

pub struct OracleData {
    pub authority: Pubkey,                  // ผู้ดูแลระบบ
    pub api_gateway: Pubkey,                // Gateway ที่อนุญาตส่งข้อมูล
    pub backup_oracles: [Pubkey; 10],       // Backup oracles (สูงสุด 10)
    
    pub total_readings: u64,                // จำนวนการอ่านทั้งหมด
    pub last_reading_timestamp: i64,        // เวลาการอ่านล่าสุด
    pub last_clearing: i64,                 // เวลา market clearing ล่าสุด
    pub created_at: i64,                    // เวลาเริ่มต้น
    
    // Validation config
    pub min_energy_value: u64,              // ค่าพลังงานต่ำสุดที่ยอมรับ
    pub max_energy_value: u64,              // ค่าพลังงานสูงสุดที่ยอมรับ
    pub max_reading_deviation_percent: u16, // % การเปลี่ยนแปลงสูงสุด
    pub min_reading_interval: u64,          // ระยะห่างขั้นต่ำระหว่างการอ่าน (วินาที)
    
    // Quality metrics
    pub total_valid_readings: u64,          // การอ่านที่ถูกต้อง
    pub total_rejected_readings: u64,       // การอ่านที่ถูกปฏิเสธ
    pub last_quality_score: u8,             // คะแนนคุณภาพ (0-100)
    pub last_consensus_timestamp: i64,      // เวลา consensus ล่าสุด
    
    // State tracking
    pub last_energy_produced: u64,          // การผลิตครั้งล่าสุด
    pub last_energy_consumed: u64,          // การใช้ครั้งล่าสุด
    pub average_reading_interval: u32,      // ระยะเวลาเฉลี่ยระหว่างการอ่าน
    
    // Flags
    pub active: u8,                         // 1 = เปิดใช้งาน, 0 = หยุด
    pub anomaly_detection_enabled: u8,      // 1 = เปิดตรวจสอบความผิดปกติ
    pub require_consensus: u8,              // 1 = ต้องใช้ consensus
    pub consensus_threshold: u8,            // จำนวน backup oraclesขั้นต่ำ
    pub backup_oracles_count: u8,           // จำนวน backup oracles ปัจจุบัน
}
```

### 7.2 Validation Logic

```
┌─────────────────────────────────────────────────────────────────────┐
│                    METER READING VALIDATION                          │
└─────────────────────────────────────────────────────────────────────┘

1. AUTHORIZATION CHECK
   ✓ Caller ต้องเป็น api_gateway ที่อนุญาต
   ✓ Oracle ต้อง active อยู่

2. TEMPORAL VALIDATION
   ✓ Monotonicity: reading_timestamp > last_reading_timestamp
   ✓ Future prevention: reading_timestamp <= now + 60s
   ✓ Rate limiting: ระยะห่าง >= min_reading_interval (60s)

3. RANGE VALIDATION
   ✓ min_energy_value <= energy_produced <= max_energy_value
   ✓ min_energy_value <= energy_consumed <= max_energy_value
   ✓ Default: 0 - 1,000,000 kWh

4. ANOMALY DETECTION (ถ้าเปิดใช้งาน)
   ✓ ratio = energy_produced / energy_consumed
   ✓ ratio <= 10.0 (ยอมรับการผลิตมากกว่าการใช้ 10 เท่า)
   ✓ ป้องกัน solar producers ที่ผลิตมากแต่ใช้น้อยมาก

5. QUALITY SCORE UPDATE
   quality_score = (total_valid_readings / total_readings) × 100
```

### 7.3 Instructions

| Instruction | Arguments | CU | Description |
|-------------|-----------|-----|-------------|
| `initialize` | api_gateway | ~7,000 | เริ่มต้น Oracle program |
| `submit_meter_reading` | meter_id, energy_produced, energy_consumed, timestamp | ~8,000 | ส่งข้อมูลมิเตอร์ (critical path) |
| `trigger_market_clearing` | - | ~2,500 | สัญญาณให้ Trading program จับคู่คำสั่ง |
| `update_oracle_status` | active: bool | ~2,800 | เปิด/ปิด oracle |
| `update_api_gateway` | new_gateway: Pubkey | ~3,000 | เปลี่ยน gateway |
| `update_validation_config` | min/max values, flags | ~3,200 | ปรับการตั้งค่า validation |
| `add_backup_oracle` | backup_oracle: Pubkey | ~3,700 | เพิ่ม backup oracle |
| `remove_backup_oracle` | backup_oracle: Pubkey | ~4,300 | ลบ backup oracle |

### 7.4 Byzantine Fault Tolerance (BFT)

```
┌─────────────────────────────────────────────────────────────────────┐
│                  BYZANTINE FAULT TOLERANCE                           │
└─────────────────────────────────────────────────────────────────────┘

โครงสร้าง:
- Primary Oracle: 1 (API Gateway)
- Backup Oracles: 0-10 (กำหนดค่าได้)
- Consensus Threshold: 2 (ค่าเริ่มต้น)

สูตร BFT:
  f = จำนวน node ที่ผิดพลาดได้
  n = จำนวน node ทั้งหมด
  threshold = n - f

  Byzantine tolerance: f < (n / 3)

ตัวอย่างการกำหนดค่า:
┌─────────────────────────────────────────────────────────────────┐
│ Backup Count │ Threshold │ BFT Tolerance │ กรณีใช้งาน          │
├─────────────────────────────────────────────────────────────────┤
│ 0            │ N/A       │ 0             │ Development/Testing  │
│ 3            │ 2         │ 1 faulty node │ Small deployment     │
│ 10           │ 7         │ 3 faulty nodes│ Production (แนะนำ)  │
│ 15           │ 11        │ 4 faulty nodes│ High-security grid   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 8. Governance Program

**Program ID:** `51d3SDcs5coxkiwvcjMzPrKeajTPF9yikw66WezipTva`  
**หน้าที่:** ออกใบรับรอง REC (Renewable Energy Certificates), จัดการ PoA configuration, voting

### 8.1 PDA Accounts

#### PoA Config PDA
```rust
Seeds: ["poa_config"]

pub struct PoAConfig {
    pub authority: Pubkey,                  // ผู้ดูแล PoA
    pub pending_authority: Pubkey,          // ผู้ดูแลใหม่ (รอการโอน)
    pub transfer_initiated_at: i64,         // เวลาเริ่มโอนอำนาจ
    pub required_signers: u8,               // จำนวน signer ขั้นต่ำ (multi-sig)
}
```

#### ERC Certificate PDA
```rust
Seeds: ["erc_certificate", certificate_id]

pub struct ERCCertificate {
    pub owner: Pubkey,                      // เจ้าของใบรับรอง
    pub meter_id: [u8; 32],                 // มิเตอร์ที่ออกใบรับรอง
    pub energy_amount: u64,                 // ปริมาณพลังงาน (kWh)
    pub energy_source: EnergySource,        // Solar/Wind/Hydro
    pub status: CertificateStatus,          // Pending/Active/Retired/Revoked
    pub issued_at: i64,                     // เวลาออกใบรับรอง
    pub validated_at: i64,                  // เวลาตรวจสอบ
    pub retired_at: i64,                    // เวลาเลิกใช้ (ถ้ามี)
}
```

### 8.2 Instructions

| Instruction | Arguments | CU | Description |
|-------------|-----------|-----|-------------|
| `initialize_poa_config` | authority, required_signers | ~5,200 | เริ่มต้น PoA configuration |
| `issue_erc` | meter_id, energy_amount, energy_source | ~6,500 | ออกใบรับรอง REC |
| `validate_erc` | certificate_id | ~4,800 | ตรวจสอบใบรับรอง REC |
| `issue_erc_with_verification` | meter_id, energy_amount, source | ~11,200 | ออก + ตรวจสอบในครั้งเดียว (CPI ไป Registry) |
| `transfer_erc` | certificate_id, new_owner | ~5,000 | โอนใบรับรอง REC |
| `revoke_erc` | certificate_id | ~3,500 | เพิกถอนใบรับรอง REC |

### 8.3 ERC Certificate Lifecycle

```
┌─────────────────────────────────────────────────────────────────────┐
│                  ERC CERTIFICATE LIFECYCLE                           │
└─────────────────────────────────────────────────────────────────────┘

1. ISSUANCE
   ┌──────────────────────────────────────────────────────────────┐
   │ Prosumer ขอใบรับรอง REC จากพลังงานที่ผลิตได้                │
   │                                                              │
   │ Governance → Registry CPI: ตรวจสอบ unclaimed energy         │
   │ Registry → ตรวจสอบ: claimed_erc_generation < net_generation │
   │                                                              │
   │ ถ้าผ่าน → ออก ERC Certificate (Active)                      │
   └──────────────────────────────────────────────────────────────┘

2. TRADING
   ┌──────────────────────────────────────────────────────────────┐
   │ ERC Certificate สามารถโอนไปยังผู้ซื้อได้                     │
   │                                                              │
   │ Trading Program → Governance CPI: validate_erc              │
   │ ตรวจสอบ: สถานะ = Active, ยังไม่หมดอายุ                       │
   └──────────────────────────────────────────────────────────────┘

3. RETIREMENT
   ┌──────────────────────────────────────────────────────────────┐
   │ ผู้ถือ ERC Certificate สามารถ "เลิกใช้" เพื่ออ้างสิทธิ์      │
   │ว่าเป็นพลังงานสะอาด (ใช้สำหรับรายงาน ESG, คาร์บอนเครดิต)      │
   │                                                              │
   │ สถานะ: Active → Retired                                     │
   └──────────────────────────────────────────────────────────────┘

4. REVOCATION (กรณีพิเศษ)
   ┌──────────────────────────────────────────────────────────────┐
   │ ผู้ดูแลระบบสามารถเพิกถอนใบรับรองหากพบปัญหา                   │
   │                                                              │
   │ สถานะ: Active/Retired → Revoked                             │
   └──────────────────────────────────────────────────────────────┘
```

---

## 9. Cross-Program Invocations (CPIs)

### 9.1 CPI Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CROSS-PROGRAM INVOCATIONS                         │
└─────────────────────────────────────────────────────────────────────┘

CPI คือการที่ program หนึ่งเรียกใช้ instruction ของอีก program
คล้ายกับการเรียก function ในภาษาปกติ แต่ข้าม program boundary

ใน GridTokenX มี CPIs สำคัญดังนี้:
```

### 9.2 Registry → Energy Token (Mint GRX)

```rust
// Registry program เรียก Energy Token program เพื่อ mint GRX

let cpi_accounts = MintTo {
    token_info: token_info_account,        // TokenInfo PDA
    mint: grid_token_mint,                 // GRX mint account
    destination: user_ata,                 // User's token account
    authority: registry_pda,               // Registry PDA (signer)
    token_program: token_program,
};

// PDA signing seeds
let seeds = &[b"registry".as_ref(), &[ctx.bumps.registry]];
let signer = &[&seeds[..]];

// Execute CPI
let cpi_ctx = CpiContext::new_with_signer(
    energy_token_program.to_account_info(),
    cpi_accounts,
    signer
);
token_interface::mint_to(cpi_ctx, grx_amount)?;
```

### 9.3 Trading → Energy Token (Transfer GRX)

```rust
// Trading program เรียก Energy Token program เพื่อโอน GRX

let cpi_accounts = TransferChecked {
    from: seller_energy_ata,               // ผู้ขาย
    to: buyer_energy_ata,                  // ผู้ซื้อ
    authority: seller_authority,           // ผู้ขาย (signer)
    mint: grid_token_mint,
    token_program: token_program,
};

let cpi_ctx = CpiContext::new(
    token_program.to_account_info(),
    cpi_accounts
);
token_interface::transfer_checked(cpi_ctx, energy_amount, decimals)?;
```

### 9.4 Trading → Governance (Validate ERC)

```rust
// Trading program เรียก Governance program เพื่อตรวจสอบ ERC

let cpi_accounts = ValidateErc {
    erc_certificate: erc_cert_account,
    governance_config: governance_config_pda,
};

let cpi_ctx = CpiContext::new(
    governance_program.to_account_info(),
    cpi_accounts
);
governance_interface::validate_erc(cpi_ctx)?;
```

### 9.5 Governance → Registry (Verify Unclaimed Energy)

```rust
// Governance program เรียก Registry program เพื่อตรวจสอบพลังงานที่ยังไม่ claim

let cpi_accounts = VerifyUnclaimedEnergy {
    meter_account: meter_pda,
    registry: registry_pda,
};

let cpi_ctx = CpiContext::new(
    registry_program.to_account_info(),
    cpi_accounts
);
registry_interface::verify_unclaimed_energy(cpi_ctx, amount)?;
```

### 9.6 CPI Summary Table

| From Program | To Program | Instruction | Purpose | CU Overhead |
|--------------|------------|-------------|---------|-------------|
| **Registry** | **Energy Token** | `mint_to_wallet` | Mint GRX จากพลังงานที่ผลิต | ~18,000 |
| **Trading** | **Energy Token** | `transfer_checked` | โอน GRX ระหว่างผู้ซื้อ-ขาย | ~15,200 |
| **Trading** | **Governance** | `validate_erc` | ตรวจสอบ ERC certificate | ~4,800 |
| **Governance** | **Registry** | `verify_unclaimed_energy` | ตรวจสอบ dual high-water marks | ~3,500 |
| **Registry** | **Trading** | (Event-driven) | แจ้งข้อมูลมิเตอร์เพื่อจับคู่ | - |

---

## 10. PDA Account Hierarchy

```
┌─────────────────────────────────────────────────────────────────────┐
│                    COMPLETE PDA HIERARCHY                            │
└─────────────────────────────────────────────────────────────────────┘

Registry Program (3aF9..W8a7)
├── Registry PDA              Seeds: ["registry"]
│   └── Global state (authority, counters, total_users, total_meters)
│
├── User PDAs                 Seeds: ["user", wallet_pubkey]
│   └── User profile, type, status, registration timestamp
│
└── Meter PDAs                Seeds: ["meter", owner, meter_id]
    └── total_production, total_consumption,
        settled_net_generation, claimed_erc_generation (dual high-water marks),
        last_reading_at

Energy Token Program (8jTD..yEur)
├── TokenInfo PDA             Seeds: ["token_info_2022"]
│   └── Controls token minting, stores registry_program_id,
│       total_supply, rec_validator list (max 10)
│
├── GRX Token Mint (Token-2022)
│   └── SPL Token-2022 mint account with Metaplex metadata
│
└── User Token Account PDAs   Seeds: ["user_token_account", wallet_pubkey]
    └── Associated token accounts for each user

Oracle Program (ACeK..AoE)
├── OracleData PDA            Seeds: ["oracle_data"]
│   └── total_valid_readings, total_rejected_readings,
│       last_clearing_timestamp, is_active
│
├── OracleAuthority PDA       Seeds: ["oracle_authority"]
│   └── Primary oracle authority (API gateway wallet)
│
└── Backup Oracle PDAs        Seeds: ["backup_oracle", oracle_pubkey]
    └── Backup oracle list for BFT consensus (max 3)

Trading Program (GTuR..ctk)
├── Market PDA                Seeds: ["market"]
│   └── total_orders, matched_orders, total_volume,
│       volume_weighted_price (avg), last_clearing_price
│
├── Order PDAs                Seeds: ["order", user_pubkey, order_counter]
│   └── order_type (Bilateral/CDA),
│       amount, filled_amount, price_per_kwh, status,
│       erc_certificate_id (optional), created_at, expires_at
│
└── Escrow PDAs               Seeds: ["escrow", order_id]
    └── Locked GRX tokens for pending orders

Governance Program (51d3..vXe)
├── PoA Config PDA            Seeds: ["poa_config"]
│   └── authority, pending_authority, transfer_initiated_at,
│       required_signers (multi-sig)
│
└── ERC Certificate PDAs      Seeds: ["erc_certificate", certificate_id]
    └── energy_amount, energy_source (Solar/Wind/Hydro),
        status (Pending/Active/Retired/Revoked),
        issued_at, validated_at, retired_at
```

---

## 11. Transaction Flow Examples

### 11.1 End-to-End: Meter Reading → GRX Mint

```
┌─────────────────────────────────────────────────────────────────────┐
│          FLOW: Smart Meter → Oracle → Registry → Energy Token        │
└─────────────────────────────────────────────────────────────────────┘

Step 1: Smart Meter ส่งข้อมูล
┌─────────────────────────────────────────────────────────────────┐
│ Smart Meter (IoT Device)                                        │
│                                                                  │
│ Data:                                                            │
│ {                                                                │
│   "meter_id": "MTR-BKK-001",                                    │
│   "energy_generated": 15.5,  // kWh                             │
│   "energy_consumed": 5.2,    // kWh                             │
│   "timestamp": 1711900800                                       │
│ }                                                                │
│                                                                  │
│ Sign with: ATECC608B Secure Element (Ed25519)                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
Step 2: Oracle Program ตรวจสอบ
┌─────────────────────────────────────────────────────────────────┐
│ Oracle Program (ACeK..AoE)                                      │
│                                                                  │
│ Validation:                                                      │
│ ✓ Authorization: Caller = api_gateway                           │
│ ✓ Temporal: timestamp > last_reading_timestamp                  │
│ ✓ Rate limit: ระยะห่าง >= 60 วินาที                            │
│ ✓ Range: 0 <= energy <= 1,000,000 kWh                          │
│ ✓ Anomaly: ratio = 15.5/5.2 = 2.98 <= 10.0 ✓                  │
│                                                                  │
│ Result: MeterReadingSubmitted event emitted                     │
│ CU: ~8,000                                                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
Step 3: Registry Program คำนวณ
┌─────────────────────────────────────────────────────────────────┐
│ Registry Program (3aF9..W8a7)                                   │
│                                                                  │
│ Calculation:                                                     │
│ net_generation = total_generated - total_consumed               │
│                  = 100 - 40 = 60 kWh                            │
│                                                                  │
│ settleable = net_generation - settled_net_generation            │
│            = 60 - 30 = 30 kWh                                   │
│                                                                  │
│ grx_minted = settleable × 10^9                                  │
│            = 30 × 10^9 = 30,000,000,000 lamports               │
│                                                                  │
│ Update: settled_net_generation = 30 → 60 kWh                   │
│ CU: ~12,000 (รวม CPI ไป Energy Token)                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
Step 4: Energy Token Program Mint
┌─────────────────────────────────────────────────────────────────┐
│ Energy Token Program (8jTD..yEur)                               │
│                                                                  │
│ Action: Mint 30 GRX to User Wallet                              │
│                                                                  │
│ CPI from Registry with PDA signing:                             │
│ seeds = [b"registry", bump]                                     │
│                                                                  │
│ Result: User มี 30 GRX ใหม่ใน wallet                            │
│ CU: ~18,000                                                      │
└─────────────────────────────────────────────────────────────────┘

Total End-to-End Latency: ~2.5 วินาที
Total CU: ~38,000
```

### 11.2 End-to-End: P2P Trade

```
┌─────────────────────────────────────────────────────────────────────┐
│          FLOW: P2P Trade (Order → Match → Settlement)               │
└─────────────────────────────────────────────────────────────────────┘

Step 1: Seller สร้างคำสั่งขาย
┌─────────────────────────────────────────────────────────────────┐
│ Trading Program (GTuR..ctk)                                     │
│                                                                  │
│ Instruction: create_sell_order                                   │
│ {                                                                │
│   "amount": 10,          // kWh                                  │
│   "price_per_kwh": 3.8,  // THB                                  │
│   "zone_id": 1                                                   │
│ }                                                                │
│                                                                  │
│ Checks:                                                          │
│ ✓ Governance: Market ไม่อยู่ใน maintenance mode                 │
│ ✓ Amount > 0                                                     │
│ ✓ Price within limits (min: 2.0, max: 5.0 THB)                 │
│ ✓ ERC certificate (ถ้ามี)                                       │
│                                                                  │
│ Result: Order PDA created                                       │
│ CU: ~7,500                                                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
Step 2: Buyer สร้างคำสั่งซื้อ
┌─────────────────────────────────────────────────────────────────┐
│ Trading Program (GTuR..ctk)                                     │
│                                                                  │
│ Instruction: create_buy_order                                    │
│ {                                                                │
│   "amount": 8,           // kWh                                  │
│   "price_per_kwh": 4.0,  // THB                                  │
│   "zone_id": 1                                                   │
│ }                                                                │
│                                                                  │
│ Result: Order PDA created                                       │
│ CU: ~7,200                                                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
Step 3: Matching Engine จับคู่
┌─────────────────────────────────────────────────────────────────┐
│ Trading Program (GTuR..ctk)                                     │
│                                                                  │
│ Matching Logic:                                                  │
│ - Price-time priority                                            │
│ - buy_price (4.0) >= sell_price (3.8) ✓ → จับคู่ได้             │
│                                                                  │
│ Match Calculation:                                               │
│ match_quantity = min(10, 8) = 8 kWh                            │
│ match_price = (3.8 + 4.0) / 2 = 3.9 THB                        │
│                                                                  │
│ P2P Costs:                                                       │
│ energy_cost = 8 × 3.9 = 31.2 THB                               │
│ wheeling_charge = 0.48 THB                                     │
│ loss_cost = 0.31 THB                                           │
│ market_fee = 31.2 × 0.0025 = 0.078 THB                         │
│ total = 31.2 + 0.48 + 0.31 + 0.078 = 32.068 THB               │
│                                                                  │
│ Result: Match record created                                    │
│ CU: ~15,000                                                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
Step 4: Atomic Settlement (3 Transactions)
┌─────────────────────────────────────────────────────────────────┐
│ Transaction #1: Lock Buyer's Funds                              │
│ Program: Trading → lock_to_escrow                               │
│ Action: 31.2 THB จาก Buyer → Escrow PDA                        │
│ CU: ~10,000                                                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Transaction #2: Transfer Energy Tokens                          │
│ Program: Energy Token → transfer_checked                        │
│ Action: 8 GRX จาก Seller → Buyer                               │
│ CU: ~15,200                                                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Transaction #3: Release Escrow to Seller                        │
│ Program: Trading → release_escrow                               │
│ Action: 31.2 THB จาก Escrow → Seller                           │
│ CU: ~9,500                                                       │
└─────────────────────────────────────────────────────────────────┘

Total Settlement Latency: ~950ms
Total CU: ~34,700 (รวม 3 transactions)
```

---

## 12. Program IDs

### Localnet (Development)

| Program | Program ID |
|---------|------------|
| **Registry** | `FmvDiFUWPrwXsqo7z7XnVniKbZDcz32U5HSDVwPug89c` |
| **Energy Token** | `n52aKuZwUeZAocpWqRZAJR4xFhQqAvaRE7Xepy2JBGk` |
| **Trading** | `69dGpKu9a8EZiZ7orgf6CoGj9DeQHHkHBF2exSr8na` |
| **Oracle** | `JDUVXMkeGi4oxLp8njBaGScAFaVBBg7iGoiqcY1LxKop` |
| **Governance** | `DamT9e1VqbA5nSyFZHExKwQu6qs4L5FW6dirWCK8YLd4` |

### Devnet/Testnet

| Program | Program ID |
|---------|------------|
| **Registry** | `3aF9FmyFuGzg4i1TCyySLQM1zWK8UUQyFALxo2f236ye` |
| **Energy Token** | `8jTDw36yCQyYdr9hTtve5D5bFuQdaJ6f3WbdM4iGPHuq` |
| **Trading** | `GTuRUUwCfvmqW7knqQtzQLMCy61p4UKUrdT5ssVgZbat` |
| **Oracle** | `ACeKwdMK1sma3EPnxy7bvgC5yMwy8tg7ZUJvaogC9YfR` |
| **Governance** | `51d3SDcs5coxkiwvcjMzPrKeajTPF9yikw66WezipTva` |

---

## สรุป

```
┌─────────────────────────────────────────────────────────────────────┐
│                    GRIDTOKENX 5 PROGRAMS SUMMARY                     │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────┬──────────────────────────────────────────────────────┐
│   PROGRAM    │                  หน้าที่หลัก                          │
├──────────────┼──────────────────────────────────────────────────────┤
│              │                                                      │
│  REGISTRY    │  • จัดการตัวตนผู้ใช้และมิเตอร์                      │
│              │  • เก็บข้อมูลการผลิต/ใช้พลังงาน                     │
│              │  • Dual high-water marks ป้องกัน claim ซ้ำ          │
│              │  • คำนวณและ mint GRX tokens                         │
│              │                                                      │
├──────────────┼──────────────────────────────────────────────────────┤
│              │                                                      │
│  ENERGY      │  • จัดการ GRX token (SPL Token-2022)               │
│  TOKEN       │  • 1 GRX = 1 kWh พลังงานสะอาด                       │
│              │  • Elastic supply (mint/burn ตามพลังงานจริง)        │
│              │  • โอน tokens ระหว่าง wallets                       │
│              │                                                      │
├──────────────┼──────────────────────────────────────────────────────┤
│              │                                                      │
│  TRADING     │  • ตลาดซื้อขายพลังงาน P2P                          │
│              │  • Order book, matching, atomic settlement          │
│              │  • 4 trading modalities (P2P, Auction, AMM, Conf.) │
│              │  • Escrow management สำหรับ trustless settlement    │
│              │                                                      │
├──────────────┼──────────────────────────────────────────────────────┤
│              │                                                      │
│  ORACLE      │  • รับและตรวจสอบข้อมูลมิเตอร์อัจฉริยะ              │
│              │  • Multi-layer validation (range, anomaly, temporal)│
│              │  • Byzantine Fault Tolerance (BFT)                  │
│              │  • Quality score tracking                           │
│              │                                                      │
├──────────────┼──────────────────────────────────────────────────────┤
│              │                                                      │
│  GOVERNANCE  │  • ออกใบรับรอง REC (Renewable Energy Certificates) │
│              │  • PoA configuration management                     │
│              │  • Voting และ protocol upgrades                     │
│              │  • ERC certificate lifecycle                        │
│              │                                                      │
└──────────────┴──────────────────────────────────────────────────────┘

ความสัมพันธ์หลัก:
  Oracle → Registry → Energy Token → Trading → Governance
    (ข้อมูล)    (คำนวณ)     (mint)      (ซื้อขาย)    (REC)

CPIs สำคัญ:
  • Registry → Energy Token: Mint GRX
  • Trading → Energy Token: Transfer GRX
  • Trading → Governance: Validate ERC
  • Governance → Registry: Verify unclaimed energy
```

---

**เอกสารที่เกี่ยวข้อง:**
- [Registry Program](./registry.md)
- [Energy Token Program](./energy-token.md)
- [Trading Program](./trading.md)
- [Oracle Program](./oracle.md)
- [Governance Program](./governance.md)
- [Transaction Settlement](./transaction-settlement.md)

**Deep Dive:**
- [Oracle Security Model](./deep-dive/oracle-security.md)
- [Settlement Architecture](./deep-dive/settlement-architecture.md)
- [AMM & Bonding Curves](./deep-dive/amm-bonding-curves.md)
- [Cross-Chain Bridge](./deep-dive/cross-chain-bridge.md)

---

**Last Updated:** 3 April 2026  
**Maintained By:** GridTokenX Engineering Team
