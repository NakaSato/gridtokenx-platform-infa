# GRID Token Lifecycle: 1 kWh = 1 GRID Token

**Version:** 1.0  
**Last Updated:** 3 April 2026  
**Status:** Living Document

---

## Table of Contents

1. [Overview](#1-overview)
2. [Token Specification](#2-token-specification)
3. [Complete Lifecycle: Energy Production → Consumption](#3-complete-lifecycle-energy-production--consumption)
4. [Phase 1: Energy Production & Measurement](#4-phase-1-energy-production--measurement)
5. [Phase 2: Oracle Validation & Attestation](#5-phase-2-oracle-validation--attestation)
6. [Phase 3: Settlement & Minting](#6-phase-3-settlement--minting)
7. [Phase 4: Trading & Transfer](#7-phase-4-trading--transfer)
8. [Phase 5: Consumption & Burning](#8-phase-5-consumption--burning)
9. [Token Flow Diagrams](#9-token-flow-diagrams)
10. [Dual High-Water Mark Prevention](#10-dual-high-water-mark-prevention)
11. [Token Economics & Supply Dynamics](#11-token-economics--supply-dynamics)
12. [Security & Trust Model](#12-security--trust-model)
13. [Performance & Throughput](#13-performance--throughput)
14. [Real-World Examples](#14-real-world-examples)
15. [Technical Implementation](#15-technical-implementation)

---

## 1. Overview

The **GRID Token (GRX)** is an energy-backed cryptocurrency where **1 GRX = 1 kWh of verified renewable energy**. Unlike traditional cryptocurrencies with arbitrary supply, GRX supply is cryptographically tied to physical energy production measured by smart meters.

### Core Principle

```
┌─────────────────────────────────────────────────────────────────────┐
│                    THE ENERGY-TOKEN PEG                              │
└─────────────────────────────────────────────────────────────────────┘

         Physical World                    Digital World
      ┌─────────────────┐              ┌─────────────────┐
      │                 │              │                 │
      │  Solar Panel    │   1:1 PEG    │   GRID Token    │
      │  Wind Turbine   │ ──────────►  │   (GRX)         │
      │  Hydro System   │   1 kWh      │   (SPL Token-   │
      │  Battery (BESS) │   Energy     │    2022)        │
      │                 │              │                 │
      └─────────────────┘              └─────────────────┘

         Measured by                      Minted by
      Smart Meter (IoT)                Energy Token Program
      (ATECC608B Secure Element)       (Solana/Anchor)
           │                                ▲
           │  Ed25519 Signature             │  CPI from Registry
           ▼                                │
      Oracle Program ────► Registry Program ┘
      (Validation)        (Settlement)
```

### Key Properties

| Property | Description |
|----------|-------------|
| **Backing** | 100% backed by verified renewable energy production |
| **Supply** | Elastic - expands with production, contracts with consumption |
| **Minting** | Only when energy is produced and validated |
| **Burning** | Optional - represents energy consumption or retirement |
| **Trust Model** | Trustless - no centralized authority controls supply |
| **Privacy** | PDPA-compliant - only ZK-proofs reach blockchain |

---

## 2. Token Specification

### GRX Token Details

| Property | Value |
|----------|-------|
| **Name** | GridTokenX Energy Token |
| **Symbol** | GRX |
| **Standard** | SPL Token-2022 (Solana Token Extensions) |
| **Program ID** | `8jTDw36yCQyYdr9hTtve5D5bFuQdaJ6f3WbdM4iGPHuq` |
| **Decimals** | 9 (nano-GRX precision for fractional kWh) |
| **Mint Authority** | PDA (seeds: `["token_info_2022"]`) |
| **Freeze Authority** | None (freely transferable) |
| **Burn Authority** | Token holder + Energy Token Program |
| **Metadata** | Metaplex Token Metadata (on-chain) |
| **REC Validators** | Max 10 authorized validators (governance-managed) |

### Token Units

```
1 GRX = 1 kWh of energy

Smallest unit (lamports):
1 GRX = 1,000,000,000 lamports (10^9)
0.001 GRX = 1,000,000 lamports (1 Wh)
0.000001 GRX = 1,000 lamports (1 mWh)

Examples:
- 10.5 kWh produced → 10,500,000,000 lamports minted
- 0.5 kWh consumed → 500,000,000 lamports burned
```

---

## 3. Complete Lifecycle: Energy Production → Consumption

### End-to-End Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│              GRID TOKEN COMPLETE LIFECYCLE                           │
└─────────────────────────────────────────────────────────────────────┘

PHASE 1: PRODUCTION          PHASE 2: VALIDATION         PHASE 3: MINTING
┌──────────────────────┐    ┌──────────────────────┐   ┌──────────────────────┐
│                      │    │                      │   │                      │
│  Solar Panel         │    │  Oracle Program      │   │  Registry Program    │
│  produces 15.5 kWh   │    │  validates reading   │   │  calculates net      │
│                      │    │                      │   │  generation          │
│  Smart Meter         │    │  ✓ Range check       │   │                      │
│  measures & signs    │───►│  ✓ Anomaly detect    │──►│  settleable =        │
│  (Ed25519)           │    │  ✓ Monotonic time    │   │  net - settled       │
│                      │    │  ✓ Rate limit        │   │                      │
│  15.5 kWh generated  │    │                      │   │  CPI: mint_tokens    │
│  5.2 kWh consumed    │    │  Emit event          │   │                      │
│  Net: 10.3 kWh       │    │                      │   │                      │
│                      │    │                      │   │                      │
└──────────────────────┘    └──────────────────────┘   └──────────┬───────────┘
                                                                   │
                                                                   ▼
                                                      ┌──────────────────────┐
                                                      │  Energy Token        │
                                                      │  Program             │
                                                      │                      │
                                                      │  Mint 10.3 GRX to    │
                                                      │  producer wallet     │
                                                      │                      │
                                                      │  Event:              │
                                                      │  GridTokensMinted    │
                                                      │                      │
                                                      └──────────┬───────────┘
                                                                 │
                                                                 ▼
PHASE 4: TRADING             PHASE 5: CONSUMPTION        ┌──────────────────────┐
┌──────────────────────┐    ┌──────────────────────┐    │                      │
│                      │    │                      │    │  Consumer uses       │
│  Producer sells      │    │  Consumer buys       │    │  energy (10.3 kWh)   │
│  10.3 GRX on         │    │  10.3 GRX from       │    │                      │
│  marketplace           │    │  producer            │    │  Optional: Burn      │
│                      │    │                      │    │  tokens to represent │
│  Atomic settlement:  │    │  Atomic settlement:  │    │  consumption         │
│  - GRX: Seller→Buyer │───►│  - GRX: Seller→Buyer │───►│                      │
│  - THB: Buyer→Seller │    │  - THB: Buyer→Seller │    │  Burn 10.3 GRX       │
│                      │    │                      │    │  → Supply decreases  │
│  Price: 3.9 THB/kWh │    │  Price: 3.9 THB/kWh   │    │                      │
│  Total: 40.17 THB   │    │  Total: 40.17 THB     │    │  Deflationary model │
│                      │    │                      │    │                      │
└──────────────────────┘    └──────────────────────┘    └──────────────────────┘
```

### Lifecycle States

```
┌─────────────────────────────────────────────────────────────────────┐
│                    GRID TOKEN STATE MACHINE                          │
└─────────────────────────────────────────────────────────────────────┘

   ┌─────────────┐
   │   NOT       │  Energy produced but not yet validated
   │   MINTED    │  (sitting in smart meter)
   └──────┬──────┘
          │
          │ Oracle validates reading
          ▼
   ┌─────────────┐
   │  PENDING    │  Reading submitted, awaiting settlement
   │ SETTLEMENT  │  (in Registry queue)
   └──────┬──────┘
          │
          │ Registry calculates net generation
          ▼
   ┌─────────────┐
   │   MINTED    │  GRX tokens created and sent to producer
   │  (Active)   │  (in producer's wallet)
   └──────┬──────┘
          │
          │ Producer lists on marketplace
          ▼
   ┌─────────────┐
   │   IN        │  GRX locked in escrow for trade
   │   ESCROW    │  (pending settlement)
   └──────┬──────┘
          │
          │ Trade completes
          ▼
   ┌─────────────┐
   │  TRANSFERRED│  GRX moved to consumer wallet
   │  (Traded)   │  (in consumer's wallet)
   └──────┬──────┘
          │
          ├──────────────┬──────────────────┐
          │              │                  │
          ▼              ▼                  ▼
   ┌─────────────┐ ┌─────────────┐  ┌─────────────┐
   │   HELD      │ │   RETIRED   │  │   BURNED    │
   │  (HODL)     │ │  (REC)      │  │(Consumption)│
   │             │ │             │  │             │
   │ Keep as     │ │ Claim as    │  │ Destroy to  │
   │ investment  │ │ green energy│  │ represent   │
   │             │ │ certificate │  │ usage       │
   └─────────────┘ └─────────────┘  └─────────────┘
```

---

## 4. Phase 1: Energy Production & Measurement

### Smart Meter Data Collection

```
┌─────────────────────────────────────────────────────────────────────┐
│              PHASE 1: ENERGY PRODUCTION & MEASUREMENT                │
└─────────────────────────────────────────────────────────────────────┘

Physical Energy Flow:
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Sunlight/Wind/Water ──► Solar Panel/Turbine ──► Inverter       │
│                                                             │
│                                                             ▼
│                                                    Electrical Output
│                                                         (AC Power)
│                                                             │
│                                                             ▼
│                                                    ┌──────────────┐
│                                                    │ Smart Meter  │
│                                                    │ (IoT Device) │
│                                                    │              │
│                                                    │ Measures:    │
│                                                    │ - Voltage    │
│                                                    │ - Current    │
│                                                    │ - Power      │
│                                                    │ - Energy     │
│                                                    └──────┬───────┘
│                                                           │
│                                                           ▼
│                                                  Integration over time
│                                                  (1-second sampling)
│                                                           │
│                                                           ▼
│                                                  Aggregation (15-sec)
│                                                  - energy_generated: 15.5 kWh
│                                                  - energy_consumed: 5.2 kWh
│                                                  - timestamp: 1711900800
│                                                           │
│                                                           ▼
│                                                  Ed25519 Signature
│                                                  (ATECC608B Secure Element)
│                                                           │
└──────────────────────────────────────────────────────────────────┘

Smart Meter Output:
```json
{
  "device_id": "MTR-BKK-001",
  "serial_number": "SN-2026-001234",
  "zone_id": 3,
  "energy_generated": 15.5,
  "energy_consumed": 5.2,
  "voltage": 230.5,
  "current": 12.3,
  "power_factor": 0.95,
  "frequency": 50.0,
  "timestamp": 1711900800,
  "signature": "ed25519_signature_hex",
  "public_key": "meter_public_key_hex"
}
```

### Key Metrics

| Metric | Value | Unit |
|--------|-------|------|
| **Sampling Rate** | 1 second | Hz |
| **Telemetry Interval** | 15 seconds | sec |
| **Attestation Interval** | 15 minutes | min |
| **Energy Precision** | 0.001 kWh | Wh |
| **Signature Algorithm** | Ed25519 | - |
| **Secure Element** | ATECC608B | Hardware |

---

## 5. Phase 2: Oracle Validation & Attestation

### Oracle Program Validation

```
┌─────────────────────────────────────────────────────────────────────┐
│              PHASE 2: ORACLE VALIDATION & ATTESTATION                │
└─────────────────────────────────────────────────────────────────────┘

Smart Meter ──HTTP POST──► Oracle Bridge ──gRPC──► Oracle Program
                                                   (Solana)

Validation Pipeline:
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Step 1: AUTHORIZATION CHECK                                     │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ ✓ Caller must be authorized api_gateway                    │ │
│  │ ✓ Oracle must be active (not paused)                       │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Step 2: TEMPORAL VALIDATION                                     │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ ✓ Monotonicity: timestamp > last_reading_timestamp         │ │
│  │   Prevents replay attacks                                   │ │
│  │                                                            │ │
│  │ ✓ Future prevention: timestamp <= now + 60s                │ │
│  │   Prevents time manipulation                                │ │
│  │                                                            │ │
│  │ ✓ Rate limiting: interval >= 60 seconds                    │ │
│  │   Prevents flooding                                         │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Step 3: RANGE VALIDATION                                        │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ ✓ min_energy_value <= energy <= max_energy_value           │ │
│  │   Default: 0 <= energy <= 1,000,000 kWh                    │ │
│  │                                                            │ │
│  │ ✓ Catches meter malfunctions                               │ │
│  │ ✓ Prevents extreme fraud                                    │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Step 4: ANOMALY DETECTION                                       │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ ✓ ratio = energy_produced / energy_consumed                │ │
│  │ ✓ ratio <= 10.0 (allows solar producers)                   │ │
│  │                                                            │ │
│  │ Example:                                                    │ │
│  │ - 15.5 / 5.2 = 2.98 ✓ (normal prosumer)                   │ │
│  │ - 1000 / 0.1 = 10,000 ✗ (anomalous, reject)               │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Step 5: QUALITY SCORE UPDATE                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ quality_score = (valid_readings / total_readings) × 100   │ │
│  │                                                            │ │
│  │ Tracks oracle reliability over time                        │ │
│  │ Can trigger automatic failover if score drops              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

Result:
┌──────────────────────────────────────────────────────────────────┐
│ If VALID:                                                         │
│ - Emit event: MeterReadingSubmitted                              │
│ - Update oracle state (last_reading_timestamp, counters)         │
│ - Forward to Registry program                                    │
│                                                                   │
│ If INVALID:                                                       │
│ - Emit event: MeterReadingRejected (with reason)                 │
│ - Increment rejected_readings counter                            │
│ - Return error to caller                                         │
└──────────────────────────────────────────────────────────────────┘

Performance:
- Compute Units: ~8,000 CU
- Latency: ~400ms (Solana confirmation)
- Throughput: ~15,000 readings/sec (theoretical)
```

---

## 6. Phase 3: Settlement & Minting

### Registry Program Settlement

```
┌─────────────────────────────────────────────────────────────────────┐
│                  PHASE 3: SETTLEMENT & MINTING                       │
└─────────────────────────────────────────────────────────────────────┘

Step 1: Calculate Net Generation
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  From MeterAccount PDA:                                          │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ total_generated = 100 kWh                                   │ │
│  │ total_consumed = 40 kWh                                     │ │
│  │                                                              │ │
│  │ net_generation = total_generated - total_consumed           │ │
│  │                  = 100 - 40 = 60 kWh                         │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

Step 2: Check Dual High-Water Marks
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Prevent double-claiming of the same energy:                     │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ settled_net_generation = 30 kWh  (GRX already minted)      │ │
│  │ claimed_erc_generation = 20 kWh  (REC already issued)      │ │
│  │                                                              │ │
│  │ Available for GRX minting:                                  │ │
│  │ settleable = net_generation - settled_net_generation       │ │
│  │            = 60 - 30 = 30 kWh                               │ │
│  │                                                              │ │
│  │ Available for REC issuance:                                 │ │
│  │ claimable = net_generation - claimed_erc_generation        │ │
│  │           = 60 - 20 = 40 kWh                                │ │
│  │                                                              │ │
│  │ ⚠️  Note: These can overlap - same energy can get both     │ │
│  │     GRX tokens AND REC certificate, but not twice for      │ │
│  │     the same type!                                          │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

Step 3: Mint GRX Tokens (CPI to Energy Token Program)
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Registry Program calls Energy Token Program via CPI:           │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Instruction: mint_tokens_direct                             │ │
│  │                                                              │ │
│  │ Arguments:                                                   │ │
│  │ - amount: 30 × 10^9 = 30,000,000,000 lamports             │ │
│  │                                                              │ │
│  │ Accounts:                                                    │ │
│  │ - token_info: TokenInfo PDA                                 │ │
│  │ - mint: GRX mint account                                    │ │
│  │ - user_token_account: Producer's GRX wallet                 │ │
│  │ - authority: Registry PDA (signer via seeds)                │ │
│  │                                                              │ │
│  │ PDA Signing:                                                 │ │
│  │ seeds = [b"registry", bump]                                 │ │
│  │ signer = &[&seeds[..]]                                      │ │
│  │                                                              │ │
│  │ CPI Execution:                                               │ │
│  │ invoke_signed(&mint_instruction, &accounts, &[signer])?;   │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

Step 4: Update State
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Update MeterAccount:                                             │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ settled_net_generation: 30 kWh → 60 kWh                    │ │
│  │                                                              │ │
│  │ Now:                                                         │ │
│  │ - net_generation = 60 kWh                                    │ │
│  │ - settled_net_generation = 60 kWh                            │ │
│  │ - Available for new minting = 0 kWh                         │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Emit Event:                                                      │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ GridTokensMinted {                                         │ │
│  │   meter_owner: Pubkey,                                     │ │
│  │   amount: 30_000_000_000,  // 30 GRX                      │ │
│  │   timestamp: i64                                           │ │
│  │ }                                                           │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

Performance:
- Registry Settlement: ~12,000 CU
- Energy Token Mint: ~18,000 CU
- Total: ~30,000 CU
- Latency: ~800ms (2 Solana transactions)
```

### Minting Formula

```rust
// Settlement calculation in Registry program
fn calculate_mint_amount(meter: &MeterAccount) -> u64 {
    let net_generation = meter.total_generated - meter.total_consumed;
    let settleable = net_generation - meter.settled_net_generation;
    
    // Convert kWh to lamports (9 decimals)
    settleable * 10u64.pow(9)
}

// Example:
// total_generated = 100 kWh
// total_consumed = 40 kWh
// settled_net_generation = 30 kWh
//
// net_generation = 100 - 40 = 60 kWh
// settleable = 60 - 30 = 30 kWh
// mint_amount = 30 × 10^9 = 30,000,000,000 lamports
```

---

## 7. Phase 4: Trading & Transfer

### P2P Marketplace Trading

```
┌─────────────────────────────────────────────────────────────────────┐
│                  PHASE 4: TRADING & TRANSFER                         │
└─────────────────────────────────────────────────────────────────────┘

Producer (Seller)                          Consumer (Buyer)
┌──────────────────────┐                  ┌──────────────────────┐
│                      │                  │                      │
│ Wallet: 30 GRX       │                  │ Wallet: 100 THB      │
│                      │                  │                      │
└──────────┬───────────┘                  └──────────┬───────────┘
           │                                         │
           │ 1. Create Sell Order                    │
           │    Amount: 10 GRX                       │
           │    Price: 3.8 THB/kWh                  │
           ▼                                         │
┌──────────────────────┐                            │
│  Trading Program     │                            │
│                      │                            │
│  Order PDA Created:  │                            │
│  - seller: producer  │                            │
│  - amount: 10 GRX   │                            │
│  - price: 3.8 THB   │                            │
│  - status: active    │                            │
└──────────┬───────────┘                            │
           │                                         │
           │                                         │ 2. Create Buy Order
           │                                         │    Amount: 8 GRX
           │                                         │    Price: 4.0 THB/kWh
           │                                         ▼
           │                            ┌──────────────────────┐
           │                            │  Trading Program     │
           │                            │                      │
           │                            │  Order PDA Created:  │
           │                            │  - buyer: consumer   │
           │                            │  - amount: 8 GRX    │
           │                            │  - price: 4.0 THB   │
           │                            │  - status: active    │
           │                            └──────────┬───────────┘
           │                                       │
           │                                       │ 3. Matching Engine
           │                                       │    buy_price (4.0) >= sell_price (3.8) ✓
           │                                       │    match_qty = min(10, 8) = 8 GRX
           │                                       │    match_price = (3.8 + 4.0) / 2 = 3.9 THB
           │                                       ▼
           │                            ┌──────────────────────┐
           │                            │  Atomic Settlement   │
           │                            │  (3 Transactions)    │
           │                            └──────────┬───────────┘
           │                                       │
           │                                       │ TX #1: Lock Buyer's Funds
           │                                       │ 8 GRX × 3.9 THB = 31.2 THB
           │                                       │ Consumer → Escrow PDA
           │                                       ▼
           │                            ┌──────────────────────┐
           │                            │  Escrow PDA          │
           │                            │  Balance: 31.2 THB  │
           │                            └──────────┬───────────┘
           │                                       │
           │                                       │ TX #2: Transfer GRX Tokens
           │                                       │ 8 GRX from Producer → Consumer
           │                                       │ (CPI to Energy Token Program)
           │                                       ▼
           │                            ┌──────────────────────┐
           │                            │  Token Transfer      │
           │                            │  Producer: 30 → 22  │
           │                            │  Consumer: 0 → 8    │
           │                            └──────────┬───────────┘
           │                                       │
           │                                       │ TX #3: Release Escrow to Seller
           │                                       │ 31.2 THB from Escrow → Producer
           │                                       ▼
           │                            ┌──────────────────────┐
           │                            │  Settlement Complete │
           │                            │  Producer: +31.2 THB│
           │                            │  Consumer: +8 GRX   │
           │                            │  Fee: 0.078 THB     │
           │                            └──────────────────────┘
           │                                       │
           ▼                                       ▼
┌──────────────────────┐                  ┌──────────────────────┐
│ Producer Final:      │                  │ Consumer Final:      │
│ - 22 GRX             │                  │ - 8 GRX              │
│ + 31.2 THB           │                  │ - 31.2 THB           │
└──────────────────────┘                  └──────────────────────┘

Performance:
- Order Creation: ~7,500 CU each
- Matching: ~15,000 CU
- Settlement (3 TXs): ~34,700 CU
- Total Latency: ~950ms
```

### Cost Breakdown

```
Trade Details:
┌──────────────────────────────────────────────────────────────────┐
│ Quantity: 8 GRX (8 kWh)                                         │
│ Clearing Price: 3.9 THB/kWh                                    │
│                                                                  │
│ Energy Cost: 8 × 3.9 = 31.2 THB                                │
│ Wheeling Charge: 0.48 THB (grid usage fee)                     │
│ Loss Cost: 0.31 THB (transmission loss)                        │
│ Market Fee: 0.078 THB (0.25% platform fee)                     │
│                                                                  │
│ Total Buyer Pays: 31.2 + 0.48 + 0.31 + 0.078 = 32.068 THB    │
│ Net Seller Receives: 31.2 THB                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 8. Phase 5: Consumption & Burning

### Token Burning Mechanisms

```
┌─────────────────────────────────────────────────────────────────────┐
│                  PHASE 5: CONSUMPTION & BURNING                      │
└─────────────────────────────────────────────────────────────────────┘

Three Burning Scenarios:

Scenario A: Energy Consumption (Optional)
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Consumer uses 8 kWh of energy in their home                    │
│                                                                  │
│  Optional Burn:                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Consumer calls: burn_tokens(8 × 10^9)                      │ │
│  │                                                              │ │
│  │ Effect:                                                      │ │
│  │ - 8 GRX removed from circulation                            │ │
│  │ - total_supply decreases                                    │ │
│  │ - Represents "energy used" conceptually                     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Note: This is OPTIONAL - consumers can hold GRX as investment  │
│        or sell back to marketplace                               │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

Scenario B: REC Retirement (Carbon Credits)
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Consumer wants to claim environmental benefits                  │
│                                                                  │
│  REC Retirement Flow:                                            │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ 1. Consumer holds 8 GRX + ERC Certificate                  │ │
│  │                                                              │ │
│  │ 2. Call Governance Program: retire_erc(certificate_id)     │ │
│  │                                                              │ │
│  │ 3. ERC Certificate status: Active → Retired                │ │
│  │                                                              │ │
│  │ 4. Optional: Burn 8 GRX to prove consumption               │ │
│  │                                                              │ │
│  │ Result:                                                      │ │
│  │ - Can claim "I used 8 kWh of renewable energy"             │ │
│  │ - Valid for ESG reporting, carbon credits                  │ │
│  │ - Cannot be resold (retired permanently)                   │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

Scenario C: Deflationary Burn (Supply Reduction)
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Governance decides to reduce supply (optional feature)         │
│                                                                  │
│  Deflationary Mechanism:                                         │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Platform buys back GRX from marketplace                    │ │
│  │ Burns tokens permanently                                    │ │
│  │                                                              │ │
│  │ Effect:                                                      │ │
│  │ - total_supply decreases                                    │ │
│  │ - Remaining GRX becomes more scarce                        │ │
│  │ - Price may increase (supply/demand)                       │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

Burn Transaction:
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Instruction: burn_tokens                                        │
│  Program: Energy Token                                           │
│                                                                  │
│  Accounts:                                                        │
│  - token_info: TokenInfo PDA (for supply tracking)              │
│  - mint: GRX mint account                                        │
│  - token_account: User's GRX wallet (source)                    │
│  - authority: User (signer)                                     │
│                                                                  │
│  Arguments:                                                       │
│  - amount: 8,000,000,000 lamports (8 GRX)                       │
│                                                                  │
│  Execution:                                                       │
│  1. CPI to Token-2022: burn(token_account, amount)              │
│  2. Update total_supply: total_supply -= amount                 │
│  3. Emit event: TokensBurned                                     │
│                                                                  │
│  Performance:                                                     │
│  - Compute Units: ~14,000 CU                                     │
│  - Latency: ~400ms                                               │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 9. Token Flow Diagrams

### Complete Token Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    GRID TOKEN COMPLETE FLOW                          │
└─────────────────────────────────────────────────────────────────────┘

                    PHYSICAL WORLD
                    ┌──────────────┐
                    │   Energy     │
                    │  Production  │
                    │  (15.5 kWh)  │
                    └──────┬───────┘
                           │
                           │ Smart Meter measures
                           ▼
                    ┌──────────────┐
                    │   Oracle     │
                    │  Validation  │
                    │  (8,000 CU)  │
                    └──────┬───────┘
                           │
                           │ Event: MeterReadingSubmitted
                           ▼
                    ┌──────────────┐
                    │  Registry    │
                    │  Settlement  │
                    │  (12,000 CU) │
                    └──────┬───────┘
                           │
                           │ CPI: mint_tokens_direct(30 GRX)
                           ▼
                    ┌──────────────┐
                    │ Energy Token │
                    │    Mint      │
                    │  (18,000 CU) │
                    └──────┬───────┘
                           │
                           │ 30 GRX minted to producer
                           ▼
                    ┌──────────────┐
                    │  Producer    │
                    │   Wallet     │
                    │  (30 GRX)    │
                    └──────┬───────┘
                           │
                           │ Lists on marketplace
                           ▼
                    ┌──────────────┐
                    │  Trading     │
                    │  Escrow      │
                    │  (10 GRX)    │
                    └──────┬───────┘
                           │
                           │ Atomic settlement
                           ▼
                    ┌──────────────┐
                    │  Consumer    │
                    │   Wallet     │
                    │  (8 GRX)     │
                    └──────┬───────┘
                           │
                    ┌──────┴──────┬──────────────┐
                    │             │              │
                    ▼             ▼              ▼
              ┌──────────┐ ┌──────────┐  ┌──────────┐
              │   HOLD   │ │  RETIRE  │  │   BURN   │
              │ (Invest) │ │  (REC)   │  │ (Consume)│
              └──────────┘ └──────────┘  └──────────┘
```

### Token Movement Summary

```
┌─────────────────────────────────────────────────────────────────────┐
│                    TOKEN MOVEMENT ACROSS PROGRAMS                    │
└─────────────────────────────────────────────────────────────────────┘

1. METER READING:   Oracle validates reading (8k CU, BFT consensus)
2. SETTLEMENT:      Registry calculates net generation (3.5k CU)
3. MINTING:         Registry → Energy Token CPI (18k CU mint)
                    ↳ PDA authority signs, 1:1 kWh:GRX ratio
4. ESCROW:          Prosumer Wallet → Trading Order Escrow (7.5k CU)
5. MATCHING:        Trading program matches orders (15k CU)
6. SETTLEMENT:      Trading → Token transfer (15.2k CU)
                    ↳ Atomic 6-way settlement for complex trades (28k CU)
7. ERC ISSUANCE:    Governance verifies unclaimed energy (11.2k CU w/ CPI)
                    ↳ Dual high-water mark check via Registry
8. BURN:            Token holder → Void (14k CU, optional tracking)
9. TRANSFER:        Wallet → Wallet (15.2k CU, peer transfer)
```

---

## 10. Dual High-Water Mark Prevention

### Preventing Double-Claiming

```
┌─────────────────────────────────────────────────────────────────────┐
│              DUAL HIGH-WATER MARK MECHANISM                          │
└─────────────────────────────────────────────────────────────────────┘

Problem:
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  A prosumer produces 60 kWh net energy.                         │
│                                                                  │
│  Without protection:                                             │
│  - Could mint 60 GRX tokens                                     │
│  - Then mint 60 GRX tokens again (double-spend!)                │
│  - Could also claim 60 kWh REC certificate                        │
│  - Then claim same 60 kWh REC again!                            │
│                                                                  │
│  Solution: Dual High-Water Marks                                │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

MeterAccount Structure:
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  pub struct MeterAccount {                                        │
│      pub total_generated: u64,           // 100 kWh              │
│      pub total_consumed: u64,            // 40 kWh               │
│      pub settled_net_generation: u64,    // 30 kWh (GRX minted) │
│      pub claimed_erc_generation: u64,    // 20 kWh (REC issued) │
│      // ... other fields                                        │
│  }                                                               │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

Calculation:
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  net_generation = total_generated - total_consumed               │
│                 = 100 - 40 = 60 kWh                              │
│                                                                  │
│  Available for GRX minting:                                      │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ settleable = net_generation - settled_net_generation       │ │
│  │            = 60 - 30 = 30 kWh                               │ │
│  │                                                              │ │
│  │ Can mint: 30 GRX                                            │ │
│  │ After mint: settled_net_generation = 60 kWh                 │ │
│  │ Next time: settleable = 60 - 60 = 0 kWh                    │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Available for REC issuance:                                     │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ claimable = net_generation - claimed_erc_generation        │ │
│  │           = 60 - 20 = 40 kWh                                │ │
│  │                                                              │ │
│  │ Can issue REC: 40 kWh                                       │ │
│  │ After issue: claimed_erc_generation = 60 kWh                │ │
│  │ Next time: claimable = 60 - 60 = 0 kWh                     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Key Insight:                                                    │
│  - settled_net_generation tracks GRX minting                    │
│  - claimed_erc_generation tracks REC issuance                   │
│  - They are INDEPENDENT - same energy can get both GRX & REC   │
│  - But each type can only be claimed ONCE per kWh               │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

Example Timeline:
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Time 1: Produce 60 kWh net                                      │
│  - settled_net_generation = 0                                    │
│  - claimed_erc_generation = 0                                    │
│  - Available: 60 GRX, 60 REC                                     │
│                                                                  │
│  Time 2: Mint 30 GRX                                             │
│  - settled_net_generation = 30                                   │
│  - claimed_erc_generation = 0                                    │
│  - Available: 30 GRX, 60 REC                                     │
│                                                                  │
│  Time 3: Issue 20 kWh REC                                        │
│  - settled_net_generation = 30                                   │
│  - claimed_erc_generation = 20                                   │
│  - Available: 30 GRX, 40 REC                                     │
│                                                                  │
│  Time 4: Produce 40 kWh more (total: 100 net)                   │
│  - settled_net_generation = 30                                   │
│  - claimed_erc_generation = 20                                   │
│  - Available: 70 GRX, 80 REC                                     │
│                                                                  │
│  Time 5: Mint 50 GRX                                             │
│  - settled_net_generation = 80                                   │
│  - claimed_erc_generation = 20                                   │
│  - Available: 20 GRX, 80 REC                                     │
│                                                                  │
│  Time 6: Issue 60 kWh REC                                        │
│  - settled_net_generation = 80                                   │
│  - claimed_erc_generation = 80                                   │
│  - Available: 20 GRX, 20 REC                                     │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 11. Token Economics & Supply Dynamics

### Elastic Supply Model

```
┌─────────────────────────────────────────────────────────────────────┐
│                  ELASTIC SUPPLY MECHANISM                            │
└─────────────────────────────────────────────────────────────────────┘

Supply Dynamics:
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  SUPPLY EXPANSION (Minting)                                      │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                                                              │ │
│  │  Energy Production ──► GRX Minting                         │ │
│  │                                                              │ │
│  │  Trigger: Oracle validates meter reading                    │ │
│  │  Rate: 1 kWh = 1 GRX                                        │ │
│  │  Authority: PDA (program-controlled)                        │ │
│  │                                                              │ │
│  │  Example:                                                    │ │
│  │  - 100 prosumers produce 50 kWh/month each                  │ │
│  │  - Monthly supply increase: 5,000 GRX                       │ │
│  │  - Annual supply increase: 60,000 GRX                       │ │
│  │                                                              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  SUPPLY CONTRACTION (Burning)                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                                                              │ │
│  │  Energy Consumption ──► GRX Burning                        │ │
│  │                                                              │ │
│  │  Trigger: User voluntarily burns tokens                     │ │
│  │  Rate: Optional (1 kWh consumed = 1 GRX burned)            │ │
│  │  Authority: Token holder                                    │ │
│  │                                                              │ │
│  │  Example:                                                    │ │
│  │  - 50 consumers burn 30 GRX/month each                      │ │
│  │  - Monthly supply decrease: 1,500 GRX                       │ │
│  │  - Annual supply decrease: 18,000 GRX                       │ │
│  │                                                              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  NET SUPPLY CHANGE                                               │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                                                              │ │
│  │  Δ Supply = Minted - Burned                                 │ │
│  │                                                              │ │
│  │  Example (Year 1):                                          │ │
│  │  - Minted: 60,000 GRX                                       │ │
│  │  - Burned: 18,000 GRX                                       │ │
│  │  - Net Increase: 42,000 GRX                                 │ │
│  │  - Total Supply: 150,000 + 42,000 = 192,000 GRX            │ │
│  │                                                              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

Supply Growth Projection:
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Quarter │ Prosumers │ Monthly Mint │ Cumulative Supply          │
│  ────────┼───────────┼──────────────┼───────────────────         │
│  Y1 Q1   │ 100       │ 50,000 GRX   │ 150,000 GRX               │
│  Y1 Q2   │ 125       │ 62,500 GRX   │ 337,500 GRX               │
│  Y1 Q3   │ 156       │ 78,000 GRX   │ 571,500 GRX               │
│  Y1 Q4   │ 195       │ 97,500 GRX   │ 864,000 GRX               │
│  Y2 Q1   │ 244       │ 122,000 GRX  │ 1,230,000 GRX             │
│  Y2 Q2   │ 305       │ 152,500 GRX  │ 1,687,500 GRX             │
│                                                                  │
│  Assumptions:                                                    │
│  - 25% quarterly prosumer growth                                 │
│  - 500 kWh/month average surplus per prosumer                   │
│  - Seasonal variation: ±20% (Thailand solar)                    │
│  - Burn rate: ~30% of minted supply                             │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 12. Security & Trust Model

### Trust Assumptions

```
┌─────────────────────────────────────────────────────────────────────┐
│                  SECURITY & TRUST MODEL                              │
└─────────────────────────────────────────────────────────────────────┘

Traditional Systems vs GridTokenX:
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  TRADITIONAL CARBON CREDITS:                                     │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                                                              │ │
│  │  Energy Production ──► Auditor ──► Registry ──► Credits    │ │
│  │                        (Human)       (Centralized)          │ │
│  │                                                              │ │
│  │  Trust Required:                                             │ │
│  │  ✗ Auditor honesty                                          │ │
│  │  ✗ Registry operator                                        │ │
│  │  ✗ No double-counting                                       │ │
│  │  ✗ Accurate measurement                                     │ │
│  │                                                              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  GRIDTOKENX:                                                     │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                                                              │ │
│  │  Energy ──► Smart Meter ──► Oracle ──► Registry ──► GRX   │ │
│  │             (Ed25519)     (On-chain)  (CPI)     (PDA Mint) │ │
│  │                                                              │ │
│  │  Trust Minimized:                                            │ │
│  │  ✓ Hardware security (ATECC608B)                            │ │
│  │  ✓ Cryptographic signatures (Ed25519)                       │ │
│  │  ✓ On-chain validation (Oracle Program)                     │ │
│  │  ✓ Program-controlled minting (PDA)                         │ │
│  │  ✓ Double-spend prevention (High-water marks)               │ │
│  │                                                              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

Security Layers:
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Layer 1: Hardware Security                                      │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ - ATECC608B Secure Element in smart meter                  │ │
│  │ - Ed25519 private key never leaves device                  │ │
│  │ - Tamper-resistant hardware                                 │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Layer 2: Cryptographic Validation                               │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ - Signature verification on every reading                  │ │
│  │ - Monotonic timestamp enforcement                          │ │
│  │ - Rate limiting prevents flooding                          │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Layer 3: On-Chain Logic                                         │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ - Oracle Program validates data integrity                  │ │
│  │ - Registry Program enforces settlement rules               │ │
│  │ - Energy Token Program controls minting via PDA            │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Layer 4: Economic Incentives                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ - Fraud detected → Oracle rejects reading                  │ │
│  │ - Invalid reading → No GRX minted                          │ │
│  │ - Double-spend attempt → High-water mark blocks            │ │
│  │ - Anomalous patterns → Quality score drops                 │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 13. Performance & Throughput

### Performance Metrics

```
┌─────────────────────────────────────────────────────────────────────┐
│                  PERFORMANCE & THROUGHPUT                            │
└─────────────────────────────────────────────────────────────────────┘

Per-Phase Performance:
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Phase 1: Production & Measurement                               │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ - Sampling: 1 second (hardware)                            │ │
│  │ - Aggregation: 15 seconds                                   │ │
│  │ - Signing: < 10ms (ATECC608B)                              │ │
│  │ - HTTP POST: ~30ms                                          │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Phase 2: Oracle Validation                                      │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ - Validation logic: ~8,000 CU                              │ │
│  │ - Solana confirmation: ~400ms                              │ │
│  │ - Event emission: < 10ms                                    │ │
│  │ - Total: ~450ms                                             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Phase 3: Settlement & Minting                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ - Registry settlement: ~12,000 CU                          │ │
│  │ - Energy Token mint: ~18,000 CU                            │ │
│  │ - 2 Solana transactions: ~800ms                            │ │
│  │ - Total: ~850ms                                             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Phase 4: Trading & Transfer                                     │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ - Order creation: ~7,500 CU                                │ │
│  │ - Matching: ~15,000 CU                                     │ │
│  │ - Atomic settlement (3 TXs): ~34,700 CU                   │ │
│  │ - Total: ~950ms                                             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Phase 5: Burning                                                │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ - Burn transaction: ~14,000 CU                             │ │
│  │ - Solana confirmation: ~400ms                              │ │
│  │ - Total: ~450ms                                             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

End-to-End Latency:
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Production → Minting: ~1.3 seconds                             │
│  (Oracle validation + Registry settlement + Token mint)         │
│                                                                  │
│  Production → Trading: ~2.25 seconds                            │
│  (Above + Order creation + Matching + Settlement)               │
│                                                                  │
│  Production → Consumption: ~2.7 seconds                         │
│  (Above + Burn transaction)                                     │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

System Throughput:
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Oracle Program: ~15,000 readings/sec (theoretical)             │
│  Energy Token Mint: ~6,665 mints/sec (theoretical)              │
│  Trading Program: ~8,000 orders/sec (theoretical)               │
│                                                                  │
│  Practical (load tested):                                        │
│  - Sustained minting: ~4,200 mints/sec                          │
│  - Sustained trading: ~1,000+ orders/sec                        │
│  - Bottleneck: RPC node account deserialization                 │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 14. Real-World Examples

### Example 1: Residential Solar Producer

```
┌─────────────────────────────────────────────────────────────────────┐
│              EXAMPLE: RESIDENTIAL SOLAR PRODUCER                     │
└─────────────────────────────────────────────────────────────────────┘

Scenario:
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  User: Somchai (Bangkok homeowner)                              │
│  Equipment: 5 kW solar panel system                             │
│  Smart Meter: MTR-BKK-001                                       │
│                                                                  │
│  Daily Production (sunny day):                                   │
│  - 06:00-18:00: Solar generation                                 │
│  - Total generated: 25 kWh                                       │
│  - Home consumption: 15 kWh                                      │
│  - Net surplus: 10 kWh                                           │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

Timeline:
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  06:00 - Solar panels start generating                          │
│  06:15 - First meter reading submitted                          │
│          - Generated: 0.5 kWh                                    │
│          - Consumed: 0.3 kWh                                     │
│          - Net: 0.2 kWh                                          │
│                                                                  │
│  06:16 - Oracle validates reading (~400ms)                      │
│  06:17 - Registry settles & mints 0.2 GRX (~800ms)             │
│                                                                  │
│  ... (continues every 15 minutes) ...                           │
│                                                                  │
│  18:00 - Solar generation stops                                 │
│  Total for day:                                                  │
│  - Generated: 25 kWh                                             │
│  - Consumed: 15 kWh                                              │
│  - Net: 10 kWh                                                   │
│  - GRX minted: 10 GRX                                            │
│                                                                  │
│  18:05 - Somchai lists 10 GRX on marketplace                    │
│          - Price: 3.8 THB/kWh                                    │
│          - Order created (~350ms)                                │
│                                                                  │
│  18:30 - Buyer matches order                                     │
│          - Match price: 3.9 THB/kWh                             │
│          - Settlement: 39 THB to Somchai                        │
│          - 10 GRX transferred to buyer                          │
│                                                                  │
│  Result:                                                         │
│  - Somchai earned: 39 THB for surplus energy                    │
│  - Buyer received: 10 kWh renewable energy                      │
│  - Platform fee: 0.0975 THB (0.25%)                             │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### Example 2: Commercial Solar Farm

```
┌─────────────────────────────────────────────────────────────────────┐
│              EXAMPLE: COMMERCIAL SOLAR FARM                          │
└─────────────────────────────────────────────────────────────────────┘

Scenario:
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Entity: Green Energy Co.                                       │
│  Equipment: 500 kW solar farm (100 panels)                      │
│  Smart Meters: 10 meters (1 per array)                          │
│                                                                  │
│  Monthly Production:                                             │
│  - Total generated: 60,000 kWh                                   │
│  - Farm consumption: 2,000 kWh (operations)                     │
│  - Net surplus: 58,000 kWh                                       │
│  - GRX minted: 58,000 GRX                                        │
│                                                                  │
│  Revenue:                                                        │
│  - Average selling price: 3.5 THB/kWh                           │
│  - Monthly revenue: 203,000 THB                                 │
│  - Annual revenue: 2,436,000 THB                                │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

Batch Processing:
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  With 10 meters, readings arrive every 15 minutes:              │
│  - 10 readings × 4 per hour × 12 hours = 480 readings/day      │
│  - 480 × 30 days = 14,400 readings/month                        │
│                                                                  │
│  Oracle throughput:                                              │
│  - 14,400 readings / (30 × 24 × 3600 seconds)                  │
│  - ~0.005 readings/sec (well within 15,000/sec capacity)        │
│                                                                  │
│  Minting efficiency:                                             │
│  - 58,000 GRX / (30 × 24 × 3600 seconds)                       │
│  - ~0.02 GRX/sec (well within 6,665/sec capacity)               │
│                                                                  │
│  Conclusion: System can handle 1000x scale                      │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 15. Technical Implementation

### Smart Contract Code Examples

#### Minting Flow (Registry → Energy Token)

```rust
// In Registry Program - settle_energy instruction

pub fn settle_energy(ctx: Context<SettleEnergy>) -> Result<()> {
    let meter = &mut ctx.accounts.meter_account;
    
    // 1. Calculate net generation
    let net_generation = meter.total_generated - meter.total_consumed;
    
    // 2. Calculate settleable amount (high-water mark check)
    let settleable = net_generation - meter.settled_net_generation;
    
    if settleable == 0 {
        return Ok(()); // Nothing to settle
    }
    
    // 3. Convert to lamports (9 decimals)
    let mint_amount = settleable * 10u64.pow(9);
    
    // 4. CPI to Energy Token Program
    let cpi_accounts = MintTokensDirect {
        token_info: ctx.accounts.token_info.to_account_info(),
        mint: ctx.accounts.grx_mint.to_account_info(),
        user_token_account: ctx.accounts.user_grx_account.to_account_info(),
        authority: ctx.accounts.registry_authority.to_account_info(),
        token_program: ctx.accounts.token_program.to_account_info(),
    };
    
    // PDA signing
    let seeds = &[b"registry".as_ref(), &[ctx.bumps.registry_authority]];
    let signer = &[&seeds[..]];
    
    let cpi_ctx = CpiContext::new_with_signer(
        ctx.accounts.energy_token_program.to_account_info(),
        cpi_accounts,
        signer
    );
    
    // Execute mint
    energy_token::cpi::mint_tokens_direct(cpi_ctx, mint_amount)?;
    
    // 5. Update high-water mark
    meter.settled_net_generation = net_generation;
    
    // 6. Emit event
    emit!(GridTokensMinted {
        meter_owner: ctx.accounts.meter_account.owner,
        amount: mint_amount,
        timestamp: Clock::get()?.unix_timestamp,
    });
    
    Ok(())
}
```

#### Burning Flow

```rust
// In Energy Token Program - burn_tokens instruction

pub fn burn_tokens(ctx: Context<BurnTokens>, amount: u64) -> Result<()> {
    // 1. Burn tokens via Token-2022
    let cpi_accounts = Burn {
        mint: ctx.accounts.mint.to_account_info(),
        from: ctx.accounts.token_account.to_account_info(),
        authority: ctx.accounts.authority.to_account_info(),
    };
    
    let cpi_ctx = CpiContext::new(
        ctx.accounts.token_program.to_account_info(),
        cpi_accounts
    );
    
    token_interface::burn(cpi_ctx, amount)?;
    
    // 2. Update total supply
    let token_info = &mut ctx.accounts.token_info;
    token_info.total_supply = token_info.total_supply.saturating_sub(amount);
    
    // 3. Emit event
    emit!(TokensBurned {
        burner: ctx.accounts.authority.key(),
        amount,
        timestamp: Clock::get()?.unix_timestamp,
    });
    
    Ok(())
}
```

### Client-Side Integration

```typescript
// TypeScript - Mint GRX from meter reading

import * as anchor from '@coral-xyz/anchor';
import { Registry } from './target/types/registry';
import { EnergyToken } from './target/types/energy_token';

// Submit meter reading
async function submitMeterReading(
  oracleProgram: Program<Oracle>,
  meterId: string,
  energyGenerated: number,
  energyConsumed: number
) {
  const tx = await oracleProgram.methods
    .submitMeterReading(
      meterId,
      new anchor.BN(energyGenerated * 1e9),
      new anchor.BN(energyConsumed * 1e9),
      new anchor.BN(Date.now())
    )
    .accounts({
      oracleData: oracleDataPDA,
      authority: gatewayWallet.publicKey,
    })
    .signers([gatewayWallet])
    .rpc();
  
  console.log('Meter reading submitted:', tx);
  return tx;
}

// Settle and mint GRX
async function settleAndMint(
  registryProgram: Program<Registry>,
  meterAccountPDA: PublicKey
) {
  const tx = await registryProgram.methods
    .settleEnergy()
    .accounts({
      meterAccount: meterAccountPDA,
      tokenInfo: tokenInfoPDA,
      grxMint: grxMintPDA,
      userGrxAccount: userGrxAccount,
      registryAuthority: registryAuthorityPDA,
    })
    .rpc();
  
  console.log('Energy settled and GRX minted:', tx);
  return tx;
}

// Burn GRX (consumption)
async function burnGRX(
  energyTokenProgram: Program<EnergyToken>,
  userGrxAccount: PublicKey,
  amount: number
) {
  const tx = await energyTokenProgram.methods
    .burnTokens(new anchor.BN(amount * 1e9))
    .accounts({
      tokenInfo: tokenInfoPDA,
      mint: grxMintPDA,
      tokenAccount: userGrxAccount,
      authority: userWallet.publicKey,
    })
    .signers([userWallet])
    .rpc();
  
  console.log('GRX burned:', tx);
  return tx;
}
```

---

## Summary

```
┌─────────────────────────────────────────────────────────────────────┐
│                    GRID TOKEN LIFECYCLE SUMMARY                      │
└─────────────────────────────────────────────────────────────────────┘

1. PRODUCTION
   - Smart meter measures energy (1 kWh = 1 GRX)
   - Ed25519 signature from secure element
   - 15-minute attestation intervals

2. VALIDATION
   - Oracle Program validates reading
   - Range, anomaly, temporal checks
   - ~8,000 CU, ~400ms latency

3. MINTING
   - Registry calculates net generation
   - Dual high-water marks prevent double-claim
   - CPI to Energy Token: mint_tokens_direct
   - ~30,000 CU total, ~800ms latency

4. TRADING
   - P2P marketplace (order book matching)
   - Atomic settlement (3 transactions)
   - ~34,700 CU, ~950ms latency

5. CONSUMPTION
   - Optional burn to represent usage
   - REC retirement for carbon credits
   - ~14,000 CU, ~400ms latency

KEY PROPERTIES:
✓ 100% energy-backed (1 GRX = 1 kWh)
✓ Elastic supply (expands/contracts with energy)
✓ Trustless minting (PDA-controlled)
✓ Double-spend prevention (high-water marks)
✓ PDPA-compliant (ZK-proofs only)
✓ High throughput (6,665+ mints/sec)
```

---

## Tokenomics and Pricing Model

### Token Definitions

**GRID Token (Energy Asset)**
- **Type**: SPL Token-2022 (Solana)
- **Role**: Represents verified energy verification (1 GRID = 1 kWh)
- **Minting**: Algorithmic minting upon Oracle verification of smart meter surplus
- **Burning**: Burned/Settled when consumed or traded for stablecoins
- **Supply**: Elastic; expands with solar generation, contracts with consumption

**Payment Token (USDC/SOL)**
- **Type**: SPL Token (Stablecoin)
- **Role**: Medium of exchange for purchasing energy
- **Stability**: Ensures predictable pricing for consumers

### Pricing Mechanisms

**Dynamic Market Price (P2P)**
The P2P market price floats freely but is influenced by the Demand/Supply Ratio:

```
R_ds = Total Buy Volume / Total Sell Volume
P_mkt = P_base × (1 + α × log10(R_ds))
```
Where α = 0.2 (sensitivity coefficient). Ideally stays within ±20% of P_base.

### Market Structure
- **Order Book**: On-chain Limit Order Book (CLOB)
- **Matching**: Double Auction
- **Clearing**: Best execution price

### Transaction Fees
- **Rate**: 25 basis points (0.25%), paid by Taker (Buyer)
- **Distribution**:
  - 40% → Grid Maintenance Fund (DSO)
  - 40% → Platform Development (Treasury)
  - 20% → Insurance Fund (Default protection)

### Economic Stress Testing
- **Flash Crash (Solar Surplus)**: Supply rises 300%, Demand drops 50% → Price drops to 0.85× P_base, incentivizing battery storage
- **Hyper-Inflation (Grid Failure)**: Supply drops 80% → Price hits cap (3.0× P_base), circuit breaker halts trading

---

**Related Documentation:**
- [Energy Token Program](./energy-token.md)
- [Registry Program](./registry.md)
- [Trading Program](./trading.md)
- [Oracle Program](./oracle.md)
- [Token Economics](../academic/05-token-economics.md)
- [Transaction Settlement](./transaction-settlement.md)

---

**Last Updated:** 3 April 2026  
**Maintained By:** GridTokenX Engineering Team
