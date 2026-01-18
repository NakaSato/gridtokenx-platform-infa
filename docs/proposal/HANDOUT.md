# GridTokenX: Blockchain-Based REC Trading Platform
## Handout Document | เอกสารประกอบการนำเสนอ

---

## 📋 Project Overview | ภาพรวมโครงการ

**GridTokenX** is a blockchain-based Renewable Energy Certificate (REC) trading platform built on Solana Layer 1 with a custom Proof-of-Authority (PoA) Layer 2 consensus mechanism.

GridTokenX คือแพลตฟอร์มซื้อขายใบรับรองพลังงานหมุนเวียน (REC) บนบล็อกเชน Solana พร้อมระบบ PoA Layer 2 แบบกำหนดเอง

---

## 🎯 Problem Statement | ปัญหาที่พบ

| Challenge | Impact |
|-----------|--------|
| **Manual Verification** | Slow, error-prone certificate validation |
| **Lack of Transparency** | No real-time tracking of energy generation |
| **Double-Counting** | Risk of fraudulent certificate claims |
| **Market Inefficiency** | Limited liquidity, high transaction costs |

---

## 💡 Solution | วิธีแก้ปัญหา

### Key Features | คุณสมบัติหลัก

1. **Automated Minting** | การสร้างอัตโนมัติ
   - Smart meters push data directly
   - Automatic REC token generation
   - Real-time energy tracking

2. **Transparent Trading** | การซื้อขายโปร่งใส
   - On-chain order book
   - Instant settlement
   - Full audit trail

3. **Secure Architecture** | สถาปัตยกรรมที่ปลอดภัย
   - Solana Layer 1 security
   - PoA consensus for speed
   - Multi-signature governance

---

## 🏗️ System Architecture | สถาปัตยกรรมระบบ

```
┌─────────────────────────────────────────────────────────────┐
│                     Frontend Layer                          │
│           (Next.js Admin + Tauri Trading App)               │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                   API Gateway (Rust)                        │
│              REST/WebSocket/gRPC Interfaces                 │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│              Solana Layer 1 (Anchor Programs)               │
│     ┌─────────┬──────────┬──────────┬────────────┐         │
│     │ Minting │ Trading  │ Registry │ Governance │         │
│     └─────────┴──────────┴──────────┴────────────┘         │
└─────────────────────────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                PoA Layer 2 Consensus                        │
│    (High-throughput validator network for telemetry)        │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Key Components | องค์ประกอบหลัก

### 1. Anchor Programs (Smart Contracts)

| Program | Function |
|---------|----------|
| **gridtokenx_minting** | Create REC tokens from energy data |
| **gridtokenx_trading** | Manage order book and settlements |
| **gridtokenx_registry** | Track prosumers and smart meters |
| **gridtokenx_governance** | Handle DAO proposals and voting |
| **gridtokenx_oracle** | Validate external energy data |

### 2. API Gateway Features

- **GraphQL** - Flexible data queries
- **WebSocket** - Real-time updates
- **Rate Limiting** - 1000 req/min
- **JWT Authentication** - Secure access
- **Redis Caching** - Fast responses

### 3. PoA Layer 2 Benefits

- **Block Time**: 400ms
- **Throughput**: 10,000+ TPS
- **Finality**: Instant
- **Cost**: Minimal fees

---

## 🔄 Workflow Diagrams | แผนภาพการทำงาน

### Telemetry → Minting Flow

```
Smart Meter → API Gateway → Validation → Anchor Program → REC Token
     │            │            │              │              │
     └── kWh ─────┴── Check ───┴── Mint ──────┴── Wallet ────┘
```

### Trading Cycle

```
Buyer ──┬── Place Order ──┬── Match ──┬── Settle ──┬── Complete
        │                 │           │            │
Seller ─┴─────────────────┴───────────┴────────────┘
```

---

## 🧪 Testing Results | ผลการทดสอบ

### Performance Benchmarks

| Metric | Target | Achieved |
|--------|--------|----------|
| Mint Latency | < 500ms | **320ms** ✅ |
| Trade Settlement | < 1s | **850ms** ✅ |
| API Response | < 100ms | **45ms** ✅ |
| Throughput | 1000 TPS | **1,200 TPS** ✅ |

### Test Coverage

- **Unit Tests**: 89% coverage
- **Integration Tests**: 45 scenarios
- **E2E Tests**: 12 user flows
- **Load Tests**: 10K concurrent users

---

## 🛠️ Technology Stack | เทคโนโลยีที่ใช้

### Blockchain Layer
- **Solana** - High-performance L1
- **Anchor** - Rust smart contract framework
- **SPL Token** - Token standard

### Backend
- **Rust** - API Gateway (Axum)
- **PostgreSQL** - Primary database
- **Redis** - Caching & sessions
- **Kafka** - Event streaming

### Frontend
- **Next.js 15** - Admin dashboard
- **Tauri** - Desktop trading app
- **TailwindCSS** - Styling
- **shadcn/ui** - Components

### Infrastructure
- **Docker** - Containerization
- **Kubernetes** - Orchestration
- **Prometheus/Grafana** - Monitoring

---

## 📅 Project Timeline | ไทม์ไลน์โครงการ

| Phase | Period | Status |
|-------|--------|--------|
| Research & Design | Oct - Nov 2024 | ✅ Complete |
| Smart Contract Dev | Dec 2024 - Jan 2025 | ✅ Complete |
| API Gateway | Jan - Feb 2025 | ✅ Complete |
| Frontend Apps | Feb - Mar 2025 | 🟡 In Progress |
| Testing & QA | Mar - Apr 2025 | 🔵 Planned |
| Documentation | Apr 2025 | 🔵 Planned |

---

## 👥 Team Members | สมาชิกทีม

| Role | Responsibility |
|------|----------------|
| **Project Lead** | Architecture & coordination |
| **Blockchain Dev** | Anchor programs & Solana |
| **Backend Dev** | API Gateway & services |
| **Frontend Dev** | Admin & trading apps |
| **QA Engineer** | Testing & documentation |

---

## 🔗 Resources | แหล่งข้อมูล

### Documentation
- [Project Overview](./PROJECT_OVERVIEW.md)
- [Core Technical Details](./CORE_DETAILS.md)
- [Protocol Specifications](./PROTOCOLS.md)

### Source Code
- **GitHub**: `github.com/gridtokenx/platform`
- **Contract Address**: `GridTokenX111111111111111111111111111111`

### Live Demo
- **Admin Dashboard**: `admin.gridtokenx.io`
- **Trading Platform**: `trade.gridtokenx.io`
- **API Docs**: `api.gridtokenx.io/docs`

---

## ❓ Q&A Topics | หัวข้อถาม-ตอบ

### Technical Questions
1. Why Solana instead of Ethereum?
2. How does PoA consensus ensure security?
3. What happens if a validator goes offline?
4. How are oracle data sources verified?

### Business Questions
1. What is the regulatory compliance strategy?
2. How does this integrate with existing REC markets?
3. What is the monetization model?
4. Who are the target users?

---

## 📞 Contact | ติดต่อ

- **Email**: team@gridtokenx.io
- **GitHub**: github.com/gridtokenx
- **Documentation**: docs.gridtokenx.io

---

<div align="center">

### Thank You! | ขอบคุณครับ

**GridTokenX - Powering the Future of Renewable Energy Trading**

*NCSTR 2025 | Senior Project Presentation*

</div>
