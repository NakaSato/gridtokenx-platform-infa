# NCSTR 2025: Comprehensive Presentation Content

**Project Title (Thai):** การพัฒนาระบบจำลองการซื้อขายพลังงานแสงอาทิตย์แบบ Peer-to-Peer ด้วย Solana Smart Contract (Anchor Framework Permissioned Environments)
**Project Title (English):** Development of a Peer-to-Peer Solar Energy Trading Simulator using Solana Smart Contract (Anchor Framework Permissioned Environments)

**ผู้จัดทำ:** นายจันทร์ธวัฒ กิริยาดี 2410717302003
**อาจารย์ที่ปรึกษา:** ดร.สุวรรณี อัศวกุลชัย

---

## Slide 1: Title Slide
- **Main Heading**: การพัฒนาระบบจำลองการซื้อขายพลังงานแสงอาทิตย์แบบ Peer-to-Peer ด้วย Solana Smart Contract
- **Sub-heading**: (Anchor Framework Permissioned Environments)
- **Author**: นายจันทร์ธวัฒ กิริยาดี (2410717302003)
- **Advisor**: ดร.สุวรรณี อัศวกุลชัย
- **Presented at**: NCSTR 2025

---

## Slide 2: Introduction & Research Motivation
- **Context**: The shift toward Distributed Energy Resources (DERs) and the rise of the "Prosumer".
- **The Problem**: Current blockchain solutions face three main challenges:
    1. **Scalability & Performance**: Existing chains struggle with high-frequency micro-transactions from smart meters.
    2. **Governance & Control**: Critical infrastructure requires permissioned oversight, not just open public networks.
    3. **Transaction Cost**: Volatile gas fees make minute-by-minute energy trading economically unviable.
- **Research Gap**: Proposing a hybrid architecture combining Solana's high-speed performance with Proof-of-Authority (PoA) governance.

---

## Slide 3: Core Concept (The Five Pillars)
1. **Tokenization**: 1 kWh = 1 GRID Token (SPL Token-2022).
2. **Escrow**: Secure locking of funds/tokens during the trade lifecycle.
3. **Matching**: Off-chain Rust matching engine using **Landed Cost**.
4. **Atomic Settlement**: "Delivery vs Payment" (DvP) executed on-chain.
5. **Automation**: Secure session tokens for hands-free trading.

---

## Slide 4: Use Case Case Studies
### UC-01: รับชำระเงิน (Process Payment)
- **Goal**: Securely capture billing details and update order status.
- **Flow**: Customer provides details → Manager verifies via Payment Gateway → Order state updated to "Paid".

### UC-02: เสนอขายพลังงาน (Submit Energy Offer)
- **Goal**: Prosumers list surplus energy on the DEX.
- **Flow**: Wallet connection → Specify Quantity (kWh) & Price (GRID) → CreateOffer transaction → PDA Address generated on-chain.

---

## Slide 5: System Architecture (The Tri-Layered Stack)
- **Consensus Layer (Solana/Anchor)**: Utilizing PoA with a single validator on localnet for maximum control and zero gas fees.
- **Middleware Layer (Rust/Tokio)**: High-speed matching and secure orchestration.
- **Edge Layer (AMI Simulator)**: A Bun/Node.js "Digital Twin" generating synthetic telemetry for meters.

---

## Slide 6: Flow Diagrams
### Register Flow
`Sign-up` -> `Verify Email` -> `Wallet Creation` -> `Meter Registration (PDA Binding)` -> `Success`

### Trading Flow
1. **Telemetry**: Meter sends data (kWh → GRID Minting).
2. **Matching**: Rust engine calculates Landed Cost every 15 mins.
3. **Execution**: Atomic Swap of GRID for Currency in one block.

---

## Slide 7: Technical Highlights (Consensus & Security)
- **Dual-State Consistency**: Optimistic Rust cache + Hard Solana Finality.
- **PDA Strategy**: Mathematically deterministic seeds `[b"meter", owner.key()]` prevent identity fraud.
- **Technical Gatekeepers**: `require!` macros enforce grid physics and market rules.

---

## Slide 8: Financial Model & Landed Cost
- **Formula**: `Final Price = Energy Price + Wheeling Charges + Transmission Loss`.
- **Revenue**: Platform fees, Utility transport fees (Wheeling), and automated REC premiums.

---

## Slide 9: Performance Indicators & Testing
- **Indicators**: Transaction Throughput (TPS) and End-to-End Latency.
- **Testing Methodology**: Using custom Rust benchmark scripts to measure simulation performance vs. blockchain finality.
- **Optimization**: Zero-copy accounts and account compression for IoT scale.

---

## Slide 10: Project Timeline
- **Stage 1 (Current - Dec 2025)**: Architecture design and initial PoC (50% Completion).
- **Stage 2 (Dec - April 2026)**: Full integration of matching engine and AMI (75% Completion).
- **Stage 3 (April - July 2026)**: Final optimization, performance audits, and full deployment (100% Completion).

---

## Slide 11: Summary
GridTokenX bridges the gap between high-performance blockchain technology and real-world energy infrastructure, providing a scalable, secure, and fair ecosystem for the next generation of energy prosumers.
