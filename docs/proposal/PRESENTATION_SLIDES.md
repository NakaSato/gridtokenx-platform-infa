# GridTokenX: P2P Solar Energy Trading
## Presentation Slides

---

# Slide 1: Title

## การพัฒนาระบบจำลองการซื้อขายพลังงานแสงอาทิตย์แบบ Peer-to-Peer ด้วย Solana Smart Contract (Anchor Framework) ในสภาพแวดล้อมแบบ Permissioned

### Development of a P2P Solar Energy Trading Simulation System using Solana Smart Contracts in Permissioned Environments

---

**ผู้จัดทำ:** นายจันทร์ธวัฒ กิริยาดี (2410717302003)

**อาจารย์ที่ปรึกษา:** ดร.สุวรรณี อัศวกุลชัย

<!-- 
SPEAKER NOTES:
สวัสดีครับกระผมนายจันทร์ธวัฒ กิริยาดี วันนี้จะมานำเสนอโครงงานวิศวกรรมคอมพิวเตอร์ในหัวข้อ "การพัฒนาระบบจำลองการซื้อขายพลังงานแสงอาทิตย์แบบ P2P บน Solana Blockchain" ครับ
โครงงานนี้มุ่งเน้นการแก้ปัญหาคอขวดของระบบพลังงานในอนาคต โดยการนำเทคโนโลยี Blockchain ประสิทธิภาพสูงมาประยุกต์ใช้ในการซื้อขายไฟฟ้าระหว่างครัวเรือนครับ
-->

---

# Slide 2: Agenda

## หัวข้อนำเสนอ

1. 🎯 **ที่มาและความสำคัญ** - Problem Statement
2. 🎯 **วัตถุประสงค์** - Research Objectives  
3. 🏗️ **สถาปัตยกรรมระบบ** - System Architecture
4. ⚙️ **เทคโนโลยีที่ใช้** - Technology Stack
5. 🔄 **การทำงานของระบบ** - System Workflow
6. 🧪 **แผนการทดสอบ** - Testing Plan
7. 📊 **ผลที่คาดหวัง** - Expected Outcomes
8. 📅 **แผนการดำเนินงาน** - Timeline

<!-- 
SPEAKER NOTES:
สำหรับการนำเสนอในวันนี้ จะครอบคลุมตั้งแต่ปัญหาที่เราพบในระบบปัจจุบัน, วัตถุประสงค์ของการวิจัย, สถาปัตยกรรมที่เราออกแบบ, เทคโนโลยีที่เลือกใช้ ไปจนถึงแผนการทดสอบและผลลัพธ์ที่คาดหวังครับ
-->

---

# Slide 3: Problem Statement

## ที่มาและความสำคัญของปัญหา

### การเปลี่ยนแปลงในภาคพลังงาน

```
Consumer ──────────────────► Prosumer
(ผู้บริโภค)                   (ผู้ผลิต + ผู้บริโภค)
```

### Solar Rooftop Growth
- การติดตั้ง Solar Rooftop เพิ่มขึ้นอย่างต่อเนื่อง
- ผู้ใช้ไฟฟ้ากลายเป็น **Prosumer** (Producer + Consumer)
- มีพลังงานส่วนเกินที่ต้องการขาย

### Pain Points
1. **ราคารับซื้อต่ำ:** การขายคืนให้รัฐได้ราคาต่ำกว่าราคาที่ซื้อมาใช้ (Net Billing)
2. **ระบบรวมศูนย์:** ขาดความยืดหยุ่นและการแข่งขัน
3. **ขาดความโปร่งใส:** ผู้ใช้ไม่รู้ว่าไฟฟ้าที่ใช้มาจากแหล่งใด

<!-- 
SPEAKER NOTES:
ปัญหาหลักเริ่มจากการเติบโตของ Solar Rooftop ครับ ทำให้เกิด "Prosumer" หรือผู้ที่ผลิตและใช้ไฟเอง แต่ปัญหาคือเมื่อมีไฟเหลือ พวกเขาขายคืนเข้าระบบได้ในราคาที่ต่ำมาก หรือบางทีก็ขายไม่ได้เลย ทำให้ไม่คุ้มทุน
แนวคิด P2P Energy Trading จึงเกิดขึ้นเพื่อให้เพื่อนบ้านซื้อขายกันเองได้โดยตรงครับ
-->

---

# Slide 4: The Problem with Current Blockchains

## ทำไม Blockchain เดิมถึงยังใช้ไม่ได้จริง? (The Trilemma)

| ปัญหา | รายละเอียด | ผลกระทบต่อระบบพลังงาน |
|-------|------------|---------------------|
| 🐌 **Scalability** | Ethereum: ~15-30 TPS | รองรับ Smart Meter ที่ส่งข้อมูลทุก 5 นาทีไม่ได้ |
| 💸 **Cost** | Gas Fee ผันผวน ($2 - $50) | แพงกว่าค่าไฟที่ซื้อขาย (Micro-transaction ไม่คุ้ม) |
| 🔓 **Privacy** | Public Permissionless | ใครก็เห็นข้อมูลการใช้ไฟ และใครก็เป็น Validator ได้ |

### Research Gap
> ยังไม่มีการพิสูจน์ว่า **Solana** (High Speed) + **PoA** (Control) จะทำงานร่วมกันได้ดีเพียงใดในบริบทนี้

<!-- 
SPEAKER NOTES:
หลายคนพยายามใช้ Blockchain มาแก้ปัญหา แต่เจอทางตันครับ
1. ช้าเกินไป: Ethereum รับ Transaction ได้น้อยมากเมื่อเทียบกับข้อมูลมิเตอร์นับล้านตัว
2. แพงเกินไป: ค่าโอนแพงกว่าค่าไฟ
3. ขาดการควบคุม: ระบบไฟฟ้าเป็นความมั่นคงของชาติ ไม่ควรให้ใครก็ได้มาตรวจสอบ
โครงงานนี้จึงเสนอทางออกด้วยการใช้ Solana ร่วมกับระบบ PoA ครับ
-->

---

# Slide 5: Research Objectives

## วัตถุประสงค์การวิจัย

### 1️⃣ ศึกษาและออกแบบสถาปัตยกรรม (Architecture)
> ผสมผสาน **Solana (Anchor)** เข้ากับ **Permissioned Network (PoA)** เพื่อปิดจุดอ่อนเรื่อง Scalability และ Governance

### 2️⃣ พัฒนาต้นแบบ (Proof-of-Concept)
> สร้างระบบจำลองที่ทำงานได้จริงตั้งแต่ **Meter -> Token -> Trading -> Settlement**

### 3️⃣ วิเคราะห์ประสิทธิภาพ (Benchmarking)
> วัดค่า **Throughput (TPS)** และ **Time-to-Finality** เพื่อยืนยันสมมติฐาน

<!-- 
SPEAKER NOTES:
วัตถุประสงค์หลักคือ 
1. ออกแบบระบบที่ "เร็ว" และ "ควบคุมได้"
2. สร้างของจริงขึ้นมาจำลองให้เห็นภาพ
3. วัดผลตัวเลขออกมาให้ชัดเจนว่าระบบนี้รองรับโหลดได้เท่าไหร่
-->

---

# Slide 6: System Architecture

## สถาปัตยกรรมระบบ 4 ชั้น (The 4-Layer Model)

```
┌─────────────────────────────────────────────┐
│ 4. APPLICATION LAYER (User Interface)       │
│    Next.js Dashboard + Real-time WebSockets │
└─────────────────────────────────────────────┘
                      │
┌─────────────────────────────────────────────┐
│ 3. MIDDLEWARE LAYER (Off-chain Logic)       │
│    Rust API Gateway + Order Matching Engine │
└─────────────────────────────────────────────┘
                      │
┌─────────────────────────────────────────────┐
│ 2. CONSENSUS LAYER (On-chain Truth)         │
│    Solana PoA Cluster + Anchor Programs     │
└─────────────────────────────────────────────┘
                      │
┌─────────────────────────────────────────────┐
│ 1. EDGE LAYER (Data Source)                 │
│    Python AMI Simulator + IoT Signatures    │
└─────────────────────────────────────────────┘
```

<!-- 
SPEAKER NOTES:
นี่คือภาพรวมระบบครับ
ล่างสุดคือ Edge Layer: มิเตอร์จำลองที่ส่งข้อมูลขึ้นมา
ถัดมาคือ Consensus Layer: ตัว Blockchain Solana ที่เก็บความจริง (The Truth)
ถัดมาคือ Middleware: สมองของระบบที่เขียนด้วย Rust คอยจัดการ Traffic และ Matching
บนสุดคือ Application: หน้าเว็บที่ผู้ใช้เห็น
-->

---

# Slide 7: Technology Stack

## เทคโนโลยีหลัก (The Trinity)

### 1. Solana & Anchor Framework
- **Why?** ประมวลผลแบบขนาน (Sealevel Runtime) และค่าธรรมเนียมต่ำมาก
- **Role:** Smart Contracts (Registry, Trading, Token)

### 2. Rust (Axum + Tokio)
- **Why?** Memory Safety และ Concurrency สูงมาก
- **Role:** API Gateway และ Matching Engine

### 3. Python (FastAPI/Pandas)
- **Why?** เก่งเรื่อง Data Science และ Simulation
- **Role:** สร้างข้อมูล Load Profile ของการใช้ไฟฟ้า

<!-- 
SPEAKER NOTES:
เราเลือกใช้เครื่องมือที่ดีที่สุดในแต่ละด้านครับ
Solana สำหรับความเร็ว Blockchain
Rust สำหรับความเร็ว Server
Python สำหรับความฉลาดในการจำลองข้อมูล
-->

---

# Slide 8: Smart Contracts (Anchor Programs)

## Anchor Programs (5 โปรแกรมหลัก)

| Program | หน้าที่สำคัญ |
|---------|------------|
| 📋 **Registry** | ลงทะเบียนมิเตอร์และผู้ใช้ (ใช้เทคนิค PDA) |
| 💱 **Trading** | เก็บ Order Book และทำ Settlement |
| 🪙 **Energy** | สร้าง (Mint) และทำลาย (Burn) เหรียญ GXT |
| 📡 **Oracle** | ประตูด่านแรกที่ตรวจสอบความถูกต้องของข้อมูลมิเตอร์ |
| 🏛️ **Governance** | ออกใบรับรอง REC และตั้งค่าธรรมเนียมระบบ |

### Technical Highlight: PDA
- **Program Derived Address** ช่วยให้เราสร้าง Account ให้ User อัตโนมัติ โดยที่ User ไม่ต้องสร้างเองและไม่ต้องเก็บ Private Key ของ Account นั้น

<!-- 
SPEAKER NOTES:
หัวใจสำคัญคือบรรดา Smart Contracts ครับ
ตัวที่สำคัญที่สุดคือ Oracle เพราะเป็นตัวเชื่อมโลกความจริงเข้าสู่ Blockchain
และ Trading Program ที่ทำหน้าที่แลกเปลี่ยนเงินกับไฟ
-->

---

# Slide 9: Token Lifecycle

## วงจรชีวิตของ GRID Token (GXT)

### 1. 🔨 MINTING (Gen -> Token)
- เมื่อมิเตอร์วัดไฟได้ 1 kWh -> Oracle ตรวจสอบ -> สั่ง Mint 1 GXT เข้ากระเป๋า Prosumer

### 2. 🔄 ATOMIC SWAP (Token -> Trade)
- **Atomic Settlement:** การแลกเปลี่ยนเกิดขึ้นพร้อมกันทั้งสองฝั่ง (ไฟไป เงินมา)
- ถ้าฝั่งไหนผิดพลาด Transaction จะ rollback ทั้งหมด (Zero Counterparty Risk)

### 3. 🔥 BURNING (Consuption -> Burn)
- เมื่อผู้ซื้อใช้ไฟฟ้า -> Smart Meter ส่งข้อมูล -> ระบบ Burn Token ทิ้ง

<!-- 
SPEAKER NOTES:
Token GXT เปรียบเสมือนตัวแทนพลังงานไฟฟ้าครับ
ผลิตปุ๊บ ได้เหรียญปั๊บ
ขายเหรียญ ก็คือการขายสิทธิ์การใช้ไฟ
ใช้ไฟไป เหรียญก็ถูกเผาทิ้ง เพื่อรักษาสมดุล Supply/Demand
-->

---

# Slide 10: AMI Simulator

## ระบบจำลองมิเตอร์อัจฉริยะ

### การจำลองพฤติกรรม (Simulation Logic)
- **Time-of-Use (TOU):** พฤติกรรมการใช้ไฟตามช่วงเวลา (เช้า/ค่ำ)
- **Solar Generation:** แปรผันตามสภาพอากาศ (แดดออก/เมฆบัง)
- **Digital Signature:** ข้อมูลทุกชุดต้องถูกเซ็นด้วย Private Key ของมิเตอร์

### Meter Types
- ☀️ **Solar Prosumer:** บ้านติดโซลาร์
- 🔌 **Consumer:** บ้านทั่วไป
- 🔋 **Prosumer + Storage:** บ้านมีแบตเตอรี่

<!-- 
SPEAKER NOTES:
เนื่องจากเราไม่มีมิเตอร์จริงเป็นหมื่นตัว ผมจึงสร้าง Simulator ขึ้นมา
มันจะจำลองพฤติกรรมคนจริงๆ เช่น ตอนเย็นกลับบ้านเปิดแอร์ ไฟพุ่งสูง แต่โซลาร์ไม่ผลิตแล้ว ต้องซื้อไฟ
แบบนี้จะทำให้เกิดการซื้อขายในตลาดครับ
-->

---

# Slide 11: Consensus Model (PoA)

## ทำไมต้อง Proof of Authority?

### Public vs. Permissioned
- **Public:** ใครก็ได้ตรวจสอบ -> ช้า, ควบคุมไม่ได้
- **PoA (Permissioned):** เฉพาะ Node ที่ได้รับเลือก (เช่น กฟผ., กฟน.) เป็นผู้ตรวจสอบ -> เร็ว, ปลอดภัย, เหมาะกับโครงสร้างพื้นฐาน

### การประยุกต์ใช้ในโครงงาน
- ใช้ **Solana Genesis Config** เพื่อกำหนด Validator Set
- ตัดกลไกการ Stake เหรียญออก (ไม่ต้องใช้ SOL มหาศาลในการรันระบบ)

<!-- 
SPEAKER NOTES:
ในโลกความเป็นจริง รัฐบาลคงไม่ยอมให้ระบบไฟฟ้าไปวิ่งบน Public Chain ที่ใครก็ไม่รู้มาคุม
เราจึงเลือกใช้ Proof of Authority คือให้หน่วยงานที่เชื่อถือได้เท่านั้นเป็นคนลงนามรับรองธุรกรรม
-->

---

# Slide 12: Business Logic: Landed Cost

## กลไกการจับคู่ราคา (Matching Engine)

ราคาที่ผู้ซื้อต้องจ่ายจริงไม่ได้มีแค่ค่าไฟ แต่มีค่าสายส่งด้วย

$$ P_{final} = P_{ask} + C_{wheeling} + C_{loss} $$

- **$P_{ask}$**: ราคาที่คนขายตั้ง (เช่น 3.0 บาท)
- **$C_{wheeling}$**: ค่าเช่าสายส่ง (จ่ายให้การไฟฟ้า)
- **$C_{loss}$**: ค่าชดเชยการสูญเสียพลังงานตามระยะทาง

> ระบบจะจับคู่ Order ที่ทำให้ $P_{final}$ ต่ำที่สุดให้ผู้ซื้อโดยอัตโนมัติ

<!-- 
SPEAKER NOTES:
จุดเด่นอีกอย่างคือความสมจริงด้านราคาครับ
เราไม่ได้จับคู่แค่ราคาเสนอขาย แต่เราคำนวณ "Landed Cost" หรือราคาจบ
ซึ่งรวมค่าสายส่งแล้ว ทำให้ระบบส่งเสริมการซื้อขายระยะใกล้ (Peer-to-Peer Local) โดยธรรมชาติเพราะค่าสายส่งถูกกว่า
-->

---

# Slide 13: Testing Plan

## แผนการทดสอบระบบ

### 1. Functional Testing
- **Unit Test:** ทดสอบแยก function (Anchor Test)
- **Integration Test:** ทดสอบ flow การซื้อขายแลกเปลี่ยน

### 2. Performance Testing (Load Test)
- **Benchmark Tool:** ใช้ k6 และ Criterion.rs
- **Target:** 
    - Throughput > 1,000 TPS
    - Latency < 1 sec

### 3. Security Testing
- **Fuzzing:** ยิงข้อมูลขยะเข้า Smart Contract
- **Replay Attack:** ป้องกันการนำข้อมูลมิเตอร์เก่ามาส่งซ้ำ

<!-- 
SPEAKER NOTES:
การทดสอบจะเข้มข้นมากครับ โดยเฉพาะ Performance
ผมจะยิง Transaction รัวๆ เหมือนมีคนใช้เป็นแสนคน เพื่อดูว่า Solana รับไหวจริงไหม
และทดสอบ Security เพื่อป้องกันการโกงมิเตอร์ครับ
-->

---

# Slide 14: Project Timeline

## แผนการดำเนินงาน (8 เดือน)

| Phase | กิจกรรมหลัก | สถานะ |
|-------|------------|-------|
| **1-2** | ศึกษาและออกแบบสถาปัตยกรรม | ✅ เสร็จสิ้น |
| **3-4** | พัฒนา Smart Contract & Simulator | 🔄 กำลังดำเนินการ |
| **5-6** | พัฒนา API Gateway & Frontend | ⏳ รอเริ่ม |
| **7** | Integration & Performance Test | ⏳ รอเริ่ม |
| **8** | สรุปผลและทำรูปเล่ม | ⏳ รอเริ่ม |

<!-- 
SPEAKER NOTES:
ตอนนี้ผมอยู่ในช่วง Phase 3-4 คือกำลังเขียน Smart Contract และทำ Simulator ครับ
คาดว่าจะเริ่มเชื่อมต่อระบบทั้งหมดได้ในเดือนที่ 5 ครับ
-->

---

# Slide 15: Expected Outcomes

## ประโยชน์ที่คาดว่าจะได้รับ

### 1. องค์ความรู้ใหม่ (Knowledge)
- การใช้ High-performance Blockchain ในงาน Utility
- Architecture Pattern สำหรับงาน IoT + Blockchain

### 2. ต้นแบบระบบ (Prototype)
- แพลตฟอร์มที่สาธิตความเป็นไปได้ของตลาดเสรีไฟฟ้า
- Sandbox สำหรับทดลองนโยบายพลังงานใหม่ๆ

### 3. ข้อมูลเชิงประจักษ์ (Empirical Data)
- ตัวเลขยืนยันประสิทธิภาพ Solana PoA ในงานจริง

<!-- 
SPEAKER NOTES:
ผลลัพธ์สุดท้าย ไม่ใช่แค่โปรแกรมที่ทำงานได้
แต่คือ "คำตอบ" ว่าเทคโนโลยีนี้พร้อมหรือยังสำหรับการปฏิวัติวงการพลังงานไทยครับ
-->

---

# Q&A

## ถาม-ตอบ

### ขอบคุณครับ

---

### Appendix: Use Cases

- **UC-01:** Register Prosumer (KYC)
- **UC-02:** Tokenize Energy (Mint GXT)
- **UC-03:** Place Sell Order
- **UC-04:** Place Buy Order
- **UC-05:** Calculate Landed Cost
- **UC-06:** Settlement & Transfer

