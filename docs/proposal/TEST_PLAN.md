# GridTokenX: Master Test Plan
## แผนการทดสอบระบบแบบครบวงจร (Comprehensive System Test Plan)

---

## 1. บทนำ (Introduction)

### 1.1 วัตถุประสงค์ (Purpose)
เอกสารฉบับนี้จัดทำขึ้นเพื่อกำหนดกรอบการทดสอบคุณภาพ (Quality Assurance) ของระบบ **GridTokenX** ตั้งแต่ระดับหน่วยย่อย (Unit Level) ไปจนถึงระดับระบบรวม (System Level) เพื่อให้มั่นใจว่าระบบสามารถรองรับการซื้อขายพลังงาน P2P ได้อย่างถูกต้อง แม่นยำ และมีประสิทธิภาพตามที่ออกแบบไว้

### 1.2 ขอบเขตการทดสอบ (Scope of Testing)

ระบบ GridTokenX ประกอบด้วย 3 องค์ประกอบหลักที่ต้องทดสอบร่วมกัน:

1.  **On-Chain Components (Solana/Anchor):**ความถูกต้องของ Smart Contract Logic, ความปลอดภัยของสินทรัพย์ (Token Safety), และการจัดการสิทธิ์ (Access Control)
2.  **Off-Chain Components (Rust Gateway):** ประสิทธิภาพของการจับคู่คำสั่ง (Matching Order), ความถูกต้องของการคำนวณราคา (Pricing Engine), และการจัดการพร้อมกัน (Concurrency)
3.  **Simulation Components (Python AMI):** ความสมจริงของข้อมูล (Data Fidelity), การส่งข้อมูลต่อเนื่อง (Stream Stability)

---

## 2. สภาพแวดล้อมการทดสอบ (Test Environment)

เพื่อให้การทดสอบมีความแม่นยำและทำซ้ำได้ (Reproducible) จะมีการจำลองสภาพแวดล้อมดังนี้:

### 2.1 Hardware Specifications (Test Server)
-   **CPU:** AMD Ryzen 9 / Intel Core i9 (16 Cores+) เพื่อจำลอง Node Validator และ Client Load
-   **RAM:** 32GB+ DDR4 เพื่อรองรับ In-memory Database และ Ledger State
-   **Storage:** NVMe SSD Gen4 (สำหรับการเขียน Log ของ Blockchain ที่รวดเร็ว)

### 2.2 Software Stack
-   **Solana Test Validator:** รันในโหมด `reset` ทุกครั้งที่เริ่ม Test Suite ใหม่
-   **Anchor Framework:** v0.29.0+
-   **Load Generator:** k6 (สำหรับการจำลอง HTTP Traffic) และ TypeScript Scripts (สำหรับ RPC Traffic)

---

## 3. ระดับการทดสอบ (Testing Levels & Strategies)

### 3.1 Unit Testing (Smart Contracts)
เน้นทดสอบ Logic ภายในของแต่ละ Program Instruction

*   **Tools:** `anchor-go` หรือ TypeScript (`mocha`/`chai`)
*   **Coverage Target:** > 90% ของ Code Lines

| Test Case ID | Module | Scenario | Expected Result |
|--------------|--------|----------|-----------------|
| **TC-UNIT-01** | Registry | Register duplicate meter ID | Error: `MeterAlreadyExists` |
| **TC-UNIT-02** | Token | Mint tokens without Oracle signature | Error: `InvalidSignature` |
| **TC-UNIT-03** | Trading | Match order with insufficient balance | Error: `InsufficientFunds` |
| **TC-UNIT-04** | Governance | Update fees by non-admin user | Error: `Unauthorized` |

### 3.2 Integration Testing (End-to-End Flows)
ทดสอบการทำงานร่วมกันข้าม Layer (Simulator -> API -> Blockchain)

*   **Scenario:** "The Happy Path of a Prosumer"
    1.  Prosumer ลงทะเบียนเข้าระบบ
    2.  Simulator ส่งค่าผลิตไฟฟ้า 10 kWh
    3.  User ได้รับ 10 GXT ใน Wallet
    4.  User ตั้งขาย 10 GXT
    5.  Consumer มาซื้อ 10 GXT
    6.  User ได้รับเงิน THB, Consumer ได้รับ GXT (และถูก Burn ทันทีถ้าเป็นการใช้จริง)

### 3.3 Performance & Load Testing
ทดสอบขีดจำกัดของระบบ (Breaking Point Analysis)

*   **Tools:** `k6`, `wrk`, Custom Rust Benchmarker

**KPIs (Key Performance Indicators):**

| Metric | Threshold (Acceptable) | Target (Excellent) |
|--------|------------------------|--------------------|
| **Throughput (TPS)** | 500 TPS | 2,000+ TPS |
| **Block Confirmation** | < 2.0s | < 0.8s |
| **Matching Latency** | < 100ms | < 10ms |
| **API Response Time** | < 200ms (P95) | < 50ms (P95) |

**Load Scenarios:**
1.  **Spike Test:** ยิง Transaction 10,000 tx พร้อมกันใน 1 วินาที เพื่อดูการจัดการคิว
2.  **Endurance Test:** รันระบบต่อเนื่อง 24 ชั่วโมง เพื่อดู Memory Leak

### 3.4 Security Testing
ทดสอบช่องโหว่ความปลอดภัย

*   **Fuzzing:** ส่งข้อมูลสุ่ม (Random Bytes) เข้า Instruction เพื่อหา Edge Cases ที่ทำให้ Program Crash
*   **Replay Attack Check:** ลองนำ Signature เก่าของมิเตอร์มาส่งซ้ำ ระบบต้องปฏิเสธ
*   **Access Control Check:** ลองใช้ Wallet ทั่วไปเรียก Function ของ Admin

---

## 4. Test Data Strategy

ข้อมูลที่ใช้ทดสอบมีความสำคัญต่อความน่าเชื่อถือของผลลัพธ์:

1.  **Deterministic Data:** ชุดข้อมูลคงที่ (Hardcoded) สำหรับ Unit Test เพื่อยืนยัน Logic ที่ถูกต้องแม่นยำ 100%
2.  **Stochastic Data:** ชุดข้อมูลสุ่ม (Randomized based on patterns) สำหรับ Load Test โดยใช้ Python Simulator generate ตามหลักสถิติ:
    -   *Sunny Day Data:* Solar ผลิตได้เต็มที่ช่วง 10:00-14:00
    -   *Cloudy Day Data:* Solar ผลิตได้น้อยลงและแกว่ง
    -   *Peak Load:* การใช้ไฟสูงช่วง 18:00-21:00

---

## 5. แผนการดำเนินการทดสอบ (Execution Plan)

### Phase 1: Local Development Test (Weeks 1-4)
-   นักพัฒนาเขียน Unit Test พร้อมกับการพัฒนา Code (TDD - Test Driven Development)
-   รัน `anchor test` ทุกครั้งก่อน Commit

### Phase 2: CI/CD Pipeline Integration (Weeks 5-6)
-   ตั้งค่า GitHub Actions
-   ทุก Pull Request ต้องผ่าน Unit Test ทั้งหมด

### Phase 3: System Integation Test (Weeks 7-8)
-   Deploy ขึ้น Localnet แบบ Full System
-   รัน Script จำลองมิเตอร์ 100 ตัว

### Phase 4: Stres Test (Week 9)
-   จำลองมิเตอร์ 10,000 ตัว
-   วัดค่า TPS และปรับแต่ง Performance (Tuning)

---

## 6. เกณฑ์การยอมรับ (Acceptance Criteria)

ระบบจะถือว่า **"ผ่าน"** การทดสอบและพร้อมส่งมอบ เมื่อ:
1.  [ ] Unit Test ผ่าน 100% และมี Coverage > 80%
2.  [ ] Integration Test ผ่านทุก Case สำคัญ (Critical Flows)
3.  [ ] ระบบสามารถรองรับ 1,000 TPS ต่อเนื่อง 5 นาทีโดยไม่ล่ม (Stable)
4.  [ ] ไม่มี Critical Security Vulnerability จากการ Scan เบื้องต้น

---

**Approver:** _________________________  
(Project Manager / Advisor)
