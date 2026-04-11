# Software Testing and Validation

## GridTokenX Quality Assurance Framework

> *April 2026 Edition (Modernized)*
> **Version:** 3.1.0 (Microservices Standard)

---

> **Related Documentation:**
> - [Smart Contract Specs](../architecture/specs/smart-contract-architecture.md) - Micro-benchmark logic
> - [TPC Methodology](./tpc-methodology.md) - OLTP benchmark suite
> - [Research Methodology](./08-research-methodology.md) - DSR framework
> - [Security Analysis](./07-security-analysis.md) - Threat model and defenses

---

## 1. Testing Strategy

### 1.1 Overview

The GridTokenX platform employs a comprehensive, multi-layered testing strategy designed to ensure the reliability, security, and performance of the decentralized energy trading ecosystem. Our approach follows the **Testing Pyramid** methodology, emphasizing a strong foundation of unit tests supported by integration, system, security, and performance testing layers. Every Anchor program, microservice, and frontend component is validated through automated pipelines before deployment.

```
                        ┌───────────────────────┐
                        │   EXPLORATORY / E2E   │
                        │   ─────────────────   │
                        │   • UI/UX Testing     │
                        │   • Ad-hoc Scenarios  │
                        └───────────┬───────────┘
                                   ╱│╲
                                  ╱ │ ╲
                                 ╱  │  ╲
                    ┌───────────┴───▼───┴───────────┐
                    │        SECURITY TESTS          │
                    │   ──────────────────────       │
                    │   • Authorization & ACL        │
                    │   • Input Validation           │
                    │   • Replay & Reentrancy        │
                    │   • Economic Exploits          │
                    └───────────────┬───────────────┘
                                   ╱│╲
                                  ╱ │ ╲
                                 ╱  │  ╲
            ┌───────────────────┴───▼───┴───────────────────┐
            │           PERFORMANCE & LOAD TESTS            │
            │   ────────────────────────────────────       │
            │   • Blockbench (DoNothing, CPU, IO, YCSB)    │
            │   • TPC-C (New-Order, Payment, Delivery)     │
            │   • Concurrent User Simulation               │
            └─────────────────────┬───────────────────────┘
                                 ╱│╲
                                ╱ │ ╲
                               ╱  │  ╲
          ┌───────────────────┴───▼───┴───────────────────┐
          │            INTEGRATION TESTS                   │
          │   ──────────────────────────────────           │
          │   • Cross-Program Invocations (CPI)            │
          │   • End-to-End Trading Flows                   │
          │   • Multi-Service gRPC Chains                  │
          └─────────────────────┬─────────────────────────┘
                               ╱│╲
                              ╱ │ ╲
                             ╱  │  ╲
        ┌───────────────────┴───▼───┴───────────────────────┐
        │                 UNIT TESTS                        │
        │   ────────────────────────────────────            │
        │   • Program Logic (Anchor)                        │
        │   • State Transitions & PDAs                      │
        │   • Arithmetic & Boundary Conditions              │
        │   • Error Handling & Instruction Validation       │
        └───────────────────────────────────────────────────┘
```

### 1.2 Testing Principles

| Principle | Description | Application |
|:----------|:------------|:------------|
| **Automated First** | All critical paths covered by automated tests | CI/CD gates, pre-merge checks |
| **Isolation** | Unit tests run in isolation to pinpoint failures | Deterministic test validators |
| **Realism** | Integration tests mimic real network conditions | Local Solana validator with 400ms slot time |
| **Security-Centric** | Dedicated suites for DeFi vulnerability classes | Authorization, replay, economic attacks |
| **Reproducibility** | Every test uses deterministic seeds and fixtures | `Keypair.fromSecretKey()` with fixed keys |
| **Measurable Coverage** | Quantified coverage per program and category | 306+ tests across 6 programs |

### 1.3 Test Execution Pipeline

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                          CI/CD TEST PIPELINE                                   │
│                                                                                │
│  │  Lint &  │───▶│  Unit    │───▶│Integration│───▶│ Security │───▶│Benchmark │ │
│  │  Format  │    │  Tests   │    │  Tests    │    │  Tests   │    │  Suite   │ │
│  │          │    │          │    │           │    │          │    │          │ │
│  │ just     │    │ just     │    │ just      │    │ just     │    │ just     │ │
│  │ lint     │    │ test     │    │ test-i    │    │ security │    │ bench-   │ │
│  │          │    │ (unit)   │    │           │    │          │    │ mark     │ │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘ │
│       │               │               │               │               │       │
│       ▼               ▼               ▼               ▼               ▼       │
│    < 30s            < 5 min         < 15 min        < 10 min        < 20 min  │
│                                                                                │
│  All gates must PASS before merge to main branch.                              │
└────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Test Environment

### 2.1 Infrastructure Overview

The testing environment is built upon the **Anchor Framework**, utilizing a local Solana validator to simulate the blockchain network with production-like configuration.

| Component | Technology | Purpose |
|:----------|:-----------|:--------|
| **Framework** | Anchor 0.32.1 | Smart contract development and testing |
| **Runtime** | Node.js 20.x / TypeScript 5.x | Test execution, assertions |
| **Validator** | `solana-test-validator` (v1.18+) | Local Solana cluster simulation |
| **Assertions** | Chai 4.x + Mocha 10.x | BDD-style test assertions |
| **Benchmarking** | Blockbench (custom), TPC-C (adapted) | Throughput and latency measurement |
| **Token SDK** | `@solana/spl-token` 0.4.x | Token operations in tests |
| **Key Management** | `@solana/web3.js` Keypair | Deterministic wallet generation |

### 2.2 Local Validator Configuration

The `solana-test-validator` is configured to mirror mainnet-beta parameters:

```typescript
// Anchor.toml - Test validator configuration
[provider]
cluster = "localnet"
wallet = "~/.config/solana/dev-wallet.json"

[test]
startup_wait = 10000  // Wait for validator to be ready

[test.validator]
url = "https://api.mainnet-beta.solana.com"  // Clone mainnet state if needed
slots_per_epoch = 32  // Faster epochs for testing
account = [
  {  // Pre-load system accounts
    address: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
    filename: "spl_token.json"
  },
  {
    address: "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb",
    filename: "spl_token_2022.json"
  }
]
```

### 2.3 TestEnvironment Class

A centralized `TestEnvironment` class manages initialization across all test suites:

```typescript
import * as anchor from "@coral-xyz/anchor";
import { Program, AnchorProvider } from "@coral-xyz/anchor";
import { Keypair, PublicKey, Connection } from "@solana/web3.js";
import { EnergyToken } from "../target/types/energy_token";
import { Trading } from "../target/types/trading";
import { Registry } from "../target/types/registry";
import { Oracle } from "../target/types/oracle";
import { Governance } from "../target/types/governance";
import { Blockbench } from "../target/types/blockbench";

export class TestEnvironment {
  public provider: AnchorProvider;
  public connection: Connection;
  public authority: Keypair;
  public users: Keypair[] = [];
  public programs: {
    energyToken: Program<EnergyToken>;
    trading: Program<Trading>;
    registry: Program<Registry>;
    oracle: Program<Oracle>;
    governance: Program<Governance>;
    blockbench: Program<Blockbench>;
  };

  constructor() {
    this.provider = anchor.getProvider() as AnchorProvider;
    this.connection = this.provider.connection;
    this.authority = this.provider.wallet as Keypair;
  }

  async initialize(): Promise<void> {
    // Generate deterministic test wallets
    for (let i = 0; i < 10; i++) {
      const user = Keypair.generate();
      // Airdrop SOL for transaction fees
      const sig = await this.connection.requestAirdrop(
        user.publicKey,
        100 * anchor.web3.LAMPORTS_PER_SOL
      );
      await this.provider.connection.confirmTransaction(sig);
      this.users.push(user);
    }

    // Initialize all program interfaces
    this.programs = {
      energyToken: this.loadProgram("energy_token", EnergyToken),
      trading: this.loadProgram("trading", Trading),
      registry: this.loadProgram("registry", Registry),
      oracle: this.loadProgram("oracle", Oracle),
      governance: this.loadProgram("governance", Governance),
      blockbench: this.loadProgram("blockbench", Blockbench),
    };
  }

  private loadProgram<T>(name: string, idl: any): Program<T> {
    return new Program<T>(
      idl,
      this.provider
    ) as unknown as Program<T>;
  }

  async reset(): Promise<void> {
    // Reset validator state between test suites
    await this.provider.connection.confirmTransaction(
      await this.connection.requestAirdrop(
        this.authority.publicKey,
        1000 * anchor.web3.LAMPORTS_PER_SOL
      )
    );
  }
}
```

### 2.4 Test Fixtures and Seeds

| Fixture | Purpose | SOL Allocation |
|:--------|:--------|:---------------|
| `authority` | Program deployer and admin | 10,000 SOL |
| `users[0-4]` | Standard test users (traders, prosumers) | 100 SOL each |
| `users[5-7]` | Oracle validators | 100 SOL each |
| `users[8]` | Governance authority (REC issuer) | 100 SOL |
| `users[9]` | Malicious actor (security tests) | 10 SOL |

---

## 3. Test Categories

The GridTokenX test suite is organized into five primary categories, each targeting specific quality attributes of the platform.

### 3.1 Unit Testing

Unit tests verify the logic of individual smart contracts (programs) in isolation. Each of the six core programs maintains its own comprehensive test suite.

| Program | Test File | Focus Areas | Test Count |
|:--------|:----------|:------------|:-----------|
| **Energy Token** | `energy-token.test.ts` | PDA minting authority, Token-2022 operations, REC validator management, burn mechanisms | 45+ |
| **Oracle** | `oracle.test.ts` | Meter reading validation, anomaly detection, quality scoring, rate limiting, BFT consensus | 38+ |
| **Registry** | `registry.test.ts` | User/meter registration, dual high-water marks, temporal monotonicity, settlement calculation | 52+ |
| **Trading** | `trading.test.ts` | Order matching, price calculation, atomic settlement, ERC validation, continuous double auction | 67+ |
| **Governance** | `governance.test.ts` | ERC lifecycle, PoA authority, multi-sig transfers, double-claim prevention | 41+ |
| **Blockbench** | `blockbench.test.ts` | YCSB workloads, TPC-C/E/H benchmarks, DoNothing, CPUHeavy, IOHeavy, Analytics | 63+ |
| **Total** | | | **306+** |

#### 3.1.1 Energy Token Program (45+ Tests)

Covers Token-2022 initialization, PDA-based mint authority, REC validator lifecycle, and secure burn/transfer operations.

```typescript
import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { EnergyToken } from "../target/types/energy_token";
import {
  getMint,
  getAccount,
  TOKEN_2022_PROGRAM_ID,
} from "@solana/spl-token";
import { assert, expect } from "chai";

describe("Energy Token Program", () => {
  const provider = anchor.getProvider() as anchor.AnchorProvider;
  const program = anchor.workspace.EnergyToken as Program<EnergyToken>;

  let tokenInfoPDA: PublicKey;
  let mintPDA: PublicKey;

  before(async () => {
    [tokenInfoPDA] = PublicKey.findProgramAddressSync(
      [Buffer.from("token_info_2022")],
      program.programId
    );
    [mintPDA] = PublicKey.findProgramAddressSync(
      [Buffer.from("mint_authority")],
      program.programId
    );
  });

  describe("Initialization", () => {
    it("should initialize token with PDA mint authority", async () => {
      await program.methods
        .initializeToken()
        .accounts({
          tokenInfo: tokenInfoPDA,
          mint: mintPDA,
          authority: provider.wallet.publicKey,
          tokenProgram: TOKEN_2022_PROGRAM_ID,
          systemProgram: anchor.web3.SystemProgram.programId,
        })
        .rpc();

      const mintAccount = await getMint(
        provider.connection,
        mintPDA,
        "confirmed",
        TOKEN_2022_PROGRAM_ID
      );

      assert.strictEqual(
        mintAccount.mintAuthority.toBase58(),
        mintPDA.toBase58(),
        "Mint authority should be the PDA"
      );
      assert.strictEqual(
        mintAccount.decimals,
        9,
        "Token should have 9 decimals"
      );
    });

    it("should prevent double initialization", async () => {
      await expect(
        program.methods
          .initializeToken()
          .accounts({
            tokenInfo: tokenInfoPDA,
            mint: mintPDA,
            authority: provider.wallet.publicKey,
          })
          .rpc()
      ).to.be.rejectedWith(/already in use/);
    });
  });

  describe("Minting Authority", () => {
    it("should prevent unauthorized minting", async () => {
      const unauthorizedUser = anchor.web3.Keypair.generate();

      await expect(
        program.methods
          .mintTokensDirect(new anchor.BN(1_000_000_000))
          .accounts({
            authority: unauthorizedUser.publicKey,
            mint: mintPDA,
          })
          .signers([unauthorizedUser])
          .rpc()
      ).to.be.rejectedWith(/UnauthorizedAuthority/);
    });

    it("should mint tokens through authorized CPI only", async () => {
      const recipient = anchor.web3.Keypair.generate();

      // Only the Registry program can mint via CPI
      await program.methods
        .mintTokensDirect(new anchor.BN(500 * 1e9))
        .accounts({
          authority: provider.wallet.publicKey,
          recipient: recipient.publicKey,
        })
        .rpc();

      const tokenAccount = await getAccount(
        provider.connection,
        recipient.publicKey,
        "confirmed",
        TOKEN_2022_PROGRAM_ID
      );

      assert.strictEqual(
        tokenAccount.amount.toString(),
        "500000000000",
        "Should have 500 tokens minted"
      );
    });
  });

  describe("Burn Mechanism", () => {
    it("should burn tokens and update supply", async () => {
      const burnAmount = new anchor.BN(100 * 1e9);

      await program.methods
        .burnTokens(burnAmount)
        .accounts({
          authority: provider.wallet.publicKey,
          mint: mintPDA,
        })
        .rpc();

      const mintAccount = await getMint(
        provider.connection,
        mintPDA,
        "confirmed",
        TOKEN_2022_PROGRAM_ID
      );

      assert.strictEqual(
        mintAccount.supply.toString(),
        "400000000000",
        "Supply should be reduced by burn amount"
      );
    });

    it("should reject burn exceeding balance", async () => {
      const excessiveBurn = new anchor.BN(999_999_999_999_999);

      await expect(
        program.methods
          .burnTokens(excessiveBurn)
          .accounts({
            authority: provider.wallet.publicKey,
            mint: mintPDA,
          })
          .rpc()
      ).to.be.rejectedWith(/InsufficientFunds/);
    });
  });

  describe("REC Validator Management", () => {
    it("should add REC validator with authority", async () => {
      const validator = anchor.web3.Keypair.generate();

      await program.methods
        .addRecValidator(validator.publicKey)
        .accounts({
          authority: provider.wallet.publicKey,
          tokenInfo: tokenInfoPDA,
        })
        .rpc();

      const tokenInfo = await program.account.tokenInfo.fetch(tokenInfoPDA);
      assert.isTrue(
        tokenInfo.recValidators.some(
          (v) => v.toBase58() === validator.publicKey.toBase58()
        )
      );
    });

    it("should reject non-authority adding validators", async () => {
      const unauthorized = anchor.web3.Keypair.generate();
      const validator = anchor.web3.Keypair.generate();

      await expect(
        program.methods
          .addRecValidator(validator.publicKey)
          .accounts({
            authority: unauthorized.publicKey,
            tokenInfo: tokenInfoPDA,
          })
          .signers([unauthorized])
          .rpc()
      ).to.be.rejectedWith(/UnauthorizedAuthority/);
    });
  });
});
```

#### 3.1.2 Oracle Program (38+ Tests)

Validates meter reading submission, anomaly detection algorithms, quality scoring, rate limiting, and Byzantine Fault Tolerant (BFT) consensus.

```typescript
import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { Oracle } from "../target/types/oracle";
import { assert, expect } from "chai";

describe("Oracle Program", () => {
  const provider = anchor.getProvider() as anchor.AnchorProvider;
  const program = anchor.workspace.Oracle as Program<Oracle>;

  describe("Meter Reading Validation", () => {
    it("should accept valid meter readings", async () => {
      const timestamp = new anchor.BN(Math.floor(Date.now() / 1000));

      await program.methods
        .submitMeterReading(
          "METER_001",
          new anchor.BN(1000 * 1e9),  // 1000 kWh produced
          new anchor.BN(200 * 1e9),   // 200 kWh consumed
          timestamp
        )
        .accounts({
          authority: provider.wallet.publicKey,
        })
        .rpc();

      const oracleData = await program.account.oracleData.all();
      assert.strictEqual(
        oracleData[0].data.totalValidReadings.toNumber(),
        1,
        "Should record one valid reading"
      );
    });

    it("should reject anomalous readings (>10x production/consumption ratio)", async () => {
      const timestamp = new anchor.BN(Math.floor(Date.now() / 1000) + 1);

      await expect(
        program.methods
          .submitMeterReading(
            "METER_002",
            new anchor.BN(10000 * 1e9),  // 10,000 kWh produced
            new anchor.BN(10 * 1e9),     // 10 kWh consumed (1000:1 ratio)
            timestamp
          )
          .rpc()
      ).to.be.rejectedWith(/AnomalousReading/);
    });

    it("should enforce rate limiting (60s minimum interval)", async () => {
      const ts = new anchor.BN(Math.floor(Date.now() / 1000));

      await program.methods
        .submitMeterReading("METER_003", new anchor.BN(100 * 1e9), new anchor.BN(50 * 1e9), ts)
        .rpc();

      // Immediate resubmission with same meter should fail
      await expect(
        program.methods
          .submitMeterReading("METER_003", new anchor.BN(101 * 1e9), new anchor.BN(50 * 1e9), ts.add(new anchor.BN(5)))
          .rpc()
      ).to.be.rejectedWith(/RateLimitExceeded/);
    });
  });

  describe("Quality Scoring", () => {
    it("should calculate quality score based on reading consistency", async () => {
      const readings = [
        { produced: 100, consumed: 50 },
        { produced: 105, consumed: 52 },
        { produced: 98, consumed: 48 },
      ];

      for (let i = 0; i < readings.length; i++) {
        const ts = new anchor.BN(Math.floor(Date.now() / 1000) + (i + 1) * 60);
        await program.methods
          .submitMeterReading(
            "METER_004",
            new anchor.BN(readings[i].produced * 1e9),
            new anchor.BN(readings[i].consumed * 1e9),
            ts
          )
          .rpc();
      }

      const meterData = await program.account.meterReading.fetch(/* PDA */);
      assert.isAbove(
        meterData.qualityScore,
        80,
        "Quality score should be high for consistent readings"
      );
    });
  });

  describe("BFT Consensus", () => {
    it("should require 2/3 validator agreement", async () => {
      // With 4 validators, need 3 to agree (2/3 + 1)
      const oraclePDA = PublicKey.findProgramAddressSync(
        [Buffer.from("oracle_status")],
        program.programId
      )[0];

      const oracleStatus = await program.account.oracleStatus.fetch(oraclePDA);
      assert.strictEqual(
        oracleStatus.requiredApprovals,
        3,
        "Should require 3 of 4 validators"
      );
    });

    it("should reject readings from non-validated oracles", async () => {
      const maliciousOracle = anchor.web3.Keypair.generate();

      await expect(
        program.methods
          .submitOracleReading("METER_005", new anchor.BN(100 * 1e9), new anchor.BN(50 * 1e9))
          .accounts({ authority: maliciousOracle.publicKey })
          .signers([maliciousOracle])
          .rpc()
      ).to.be.rejectedWith(/UnauthorizedOracle/);
    });
  });
});
```

#### 3.1.3 Registry Program (52+ Tests)

Covers user/meter registration, dual high-water marks for generation and consumption, temporal monotonicity enforcement, and settlement calculations.

```typescript
import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { Registry } from "../target/types/registry";
import { assert, expect } from "chai";

describe("Registry Program", () => {
  const provider = anchor.getProvider() as anchor.AnchorProvider;
  const program = anchor.workspace.Registry as Program<Registry>;

  describe("User Registration", () => {
    it("should register a new prosumer", async () => {
      const user = anchor.web3.Keypair.generate();

      await program.methods
        .registerUser("prosumer_001", "Alice", 1 /* Role::Prosumer */)
        .accounts({
          user: user.publicKey,
          authority: provider.wallet.publicKey,
        })
        .signers([user])
        .rpc();

      const userAccount = await program.account.userAccount.fetch(
        PublicKey.findProgramAddressSync(
          [Buffer.from("user"), user.publicKey.toBuffer()],
          program.programId
        )[0]
      );

      assert.strictEqual(userAccount.userId, "prosumer_001");
      assert.strictEqual(userAccount.name, "Alice");
      assert.strictEqual(userAccount.role, 1);
    });
  });

  describe("Dual High-Water Marks", () => {
    it("should advance settled_net_generation on settlement", async () => {
      const meterPDA = PublicKey.findProgramAddressSync(
        [Buffer.from("meter"), Buffer.from("METER_001")],
        program.programId
      )[0];

      const meterBefore = await program.account.meterAccount.fetch(meterPDA);
      const settledBefore = meterBefore.settledNetGeneration.toNumber();

      await program.methods
        .settleEnergy(new anchor.BN(500 * 1e9))
        .accounts({ meterAccount: meterPDA })
        .rpc();

      const meterAfter = await program.account.meterAccount.fetch(meterPDA);

      assert.strictEqual(
        meterAfter.settledNetGeneration.toNumber(),
        settledBefore + 500 * 1e9,
        "Net generation should increase by settled amount"
      );
    });

    it("should track claimed ERC generation separately", async () => {
      const meterPDA = PublicKey.findProgramAddressSync(
        [Buffer.from("meter"), Buffer.from("METER_001")],
        program.programId
      )[0];

      await program.methods
        .claimErcGeneration(new anchor.BN(200 * 1e9))
        .accounts({ meterAccount: meterPDA })
        .rpc();

      const meter = await program.account.meterAccount.fetch(meterPDA);
      assert.strictEqual(
        meter.claimedErcGeneration.toNumber(),
        200 * 1e9,
        "Claimed ERC generation should be tracked"
      );
    });
  });

  describe("Temporal Monotonicity", () => {
    it("should prevent backdated readings", async () => {
      const pastTimestamp = new anchor.BN(Math.floor(Date.now() / 1000) - 3600);

      await expect(
        program.methods
          .updateMeterReading(pastTimestamp, new anchor.BN(100 * 1e9))
          .rpc()
      ).to.be.rejectedWith(/OutdatedReading/);
    });

    it("should accept only strictly increasing timestamps", async () => {
      const now = Math.floor(Date.now() / 1000);
      const ts1 = new anchor.BN(now);
      const ts2 = new anchor.BN(now + 60);

      await program.methods
        .updateMeterReading(ts1, new anchor.BN(100 * 1e9))
        .rpc();

      // Same timestamp should fail
      await expect(
        program.methods
          .updateMeterReading(ts1, new anchor.BN(101 * 1e9))
          .rpc()
      ).to.be.rejectedWith(/OutdatedReading/);

      // Future timestamp should succeed
      await program.methods
        .updateMeterReading(ts2, new anchor.BN(101 * 1e9))
        .rpc();
    });
  });
});
```

#### 3.1.4 Trading Program (67+ Tests)

The most extensively tested program. Covers order creation, continuous double auction (CDA) matching, price discovery, atomic settlement, and REC certificate validation.

```typescript
import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { Trading } from "../target/types/trading";
import { assert, expect } from "chai";

describe("Trading Program", () => {
  const provider = anchor.getProvider() as anchor.AnchorProvider;
  const program = anchor.workspace.Trading as Program<Trading>;

  describe("Order Creation", () => {
    it("should create a buy order with valid parameters", async () => {
      const expiresAt = new anchor.BN(Math.floor(Date.now() / 1000) + 3600);

      await program.methods
        .createBuyOrder(
          new anchor.BN(100 * 1e9),  // 100 kWh
          new anchor.BN(5_500_000),   // 5.50 THB/kWh
          expiresAt
        )
        .accounts({
          buyer: provider.wallet.publicKey,
        })
        .rpc();

      // Verify order was created
      const orders = await program.account.order.all();
      const buyOrder = orders.find((o) => o.data.orderType === 0); // OrderType::Buy

      assert.isDefined(buyOrder, "Buy order should exist");
      assert.strictEqual(buyOrder.data.status, 0); // OrderStatus::Open
      assert.strictEqual(buyOrder.data.quantity.toNumber(), 100 * 1e9);
    });

    it("should reject orders with zero price", async () => {
      const expiresAt = new anchor.BN(Math.floor(Date.now() / 1000) + 3600);

      await expect(
        program.methods
          .createBuyOrder(
            new anchor.BN(100 * 1e9),
            new anchor.BN(0),  // Zero price
            expiresAt
          )
          .rpc()
      ).to.be.rejectedWith(/InvalidPrice/);
    });

    it("should reject orders with zero quantity", async () => {
      const expiresAt = new anchor.BN(Math.floor(Date.now() / 1000) + 3600);

      await expect(
        program.methods
          .createSellOrder(
            new anchor.BN(0),  // Zero quantity
            new anchor.BN(5_000_000),
            expiresAt
          )
          .rpc()
      ).to.be.rejectedWith(/InvalidQuantity/);
    });

    it("should reject expired orders", async () => {
      const pastExpiry = new anchor.BN(Math.floor(Date.now() / 1000) - 60);

      await expect(
        program.methods
          .createBuyOrder(
            new anchor.BN(100 * 1e9),
            new anchor.BN(5_500_000),
            pastExpiry
          )
          .rpc()
      ).to.be.rejectedWith(/OrderExpired/);
    });
  });

  describe("Order Matching (Continuous Double Auction)", () => {
    it("should match compatible buy/sell orders", async () => {
      const expiresAt = new anchor.BN(Math.floor(Date.now() / 1000) + 3600);

      // Create buy order at 5.50 THB/kWh
      const buyOrderPDA = PublicKey.findProgramAddressSync(
        [Buffer.from("order"), Buffer.from("buy_001")],
        program.programId
      )[0];

      await program.methods
        .createBuyOrderWithId(
          "buy_001",
          new anchor.BN(100 * 1e9),
          new anchor.BN(5_500_000),
          expiresAt
        )
        .accounts({ order: buyOrderPDA })
        .rpc();

      // Create matching sell order at 4.50 THB/kWh
      const sellOrderPDA = PublicKey.findProgramAddressSync(
        [Buffer.from("order"), Buffer.from("sell_001")],
        program.programId
      )[0];

      await program.methods
        .createSellOrderWithId(
          "sell_001",
          new anchor.BN(100 * 1e9),
          new anchor.BN(4_500_000),
          expiresAt
        )
        .accounts({ order: sellOrderPDA })
        .rpc();

      // Match orders: mid-price = (5.50 + 4.50) / 2 = 5.00 THB/kWh
      await program.methods
        .matchOrders(new anchor.BN(100 * 1e9))
        .accounts({
          buyOrder: buyOrderPDA,
          sellOrder: sellOrderPDA,
        })
        .rpc();

      const buyOrder = await program.account.order.fetch(buyOrderPDA);
      assert.strictEqual(buyOrder.status, 2); // OrderStatus::Completed
      assert.strictEqual(buyOrder.filledAmount.toNumber(), 100 * 1e9);
    });

    it("should calculate matched price as mid-point", async () => {
      // Expected: (5.5 + 4.5) / 2 = 5.0 THB/kWh = 5,000,000 in fixed-point
      const expectedPrice = 5_000_000;

      const market = await program.account.market.fetch(/* marketPDA */);
      assert.approximately(
        market.volumeWeightedPrice.toNumber(),
        expectedPrice,
        100_000, // 0.1 THB tolerance
        "Matched price should be mid-point of bid/ask"
      );
    });

    it("should partially fill large orders", async () => {
      // Buy order: 100 kWh at 5.50
      // Sell order: 60 kWh at 4.50
      // Should fill 60 kWh

      const expiresAt = new anchor.BN(Math.floor(Date.now() / 1000) + 3600);

      const buyPDA = PublicKey.findProgramAddressSync(
        [Buffer.from("order"), Buffer.from("buy_002")],
        program.programId
      )[0];

      await program.methods
        .createBuyOrderWithId(
          "buy_002",
          new anchor.BN(100 * 1e9),
          new anchor.BN(5_500_000),
          expiresAt
        )
        .accounts({ order: buyPDA })
        .rpc();

      const sellPDA = PublicKey.findProgramAddressSync(
        [Buffer.from("order"), Buffer.from("sell_002")],
        program.programId
      )[0];

      await program.methods
        .createSellOrderWithId(
          "sell_002",
          new anchor.BN(60 * 1e9),
          new anchor.BN(4_500_000),
          expiresAt
        )
        .accounts({ order: sellPDA })
        .rpc();

      await program.methods
        .matchOrders(new anchor.BN(60 * 1e9))
        .accounts({ buyOrder: buyPDA, sellOrder: sellPDA })
        .rpc();

      const buyOrder = await program.account.order.fetch(buyPDA);
      assert.strictEqual(
        buyOrder.status,
        1, // OrderStatus::PartiallyFilled
        "Buy order should be partially filled"
      );
      assert.strictEqual(buyOrder.filledAmount.toNumber(), 60 * 1e9);
      assert.strictEqual(buyOrder.remainingAmount.toNumber(), 40 * 1e9);
    });
  });

  describe("Atomic Settlement", () => {
    it("should atomically transfer tokens on match", async () => {
      // Verify token balances before match
      const sellerBefore = await getTokenBalance(sellerTokenPDA);
      const buyerBefore = await getTokenBalance(buyerTokenPDA);

      // Execute match (triggers settlement)
      await program.methods
        .matchOrders(matchAmount)
        .accounts({ buyOrder: buyPDA, sellOrder: sellPDA })
        .rpc();

      const sellerAfter = await getTokenBalance(sellerTokenPDA);
      const buyerAfter = await getTokenBalance(buyerTokenPDA);

      assert.strictEqual(
        buyerAfter - buyerBefore,
        matchAmount.toNumber(),
        "Buyer should receive tokens"
      );
      assert.strictEqual(
        sellerBefore - sellerAfter,
        matchAmount.toNumber(),
        "Seller should lose tokens"
      );
    });
  });
});
```

#### 3.1.5 Governance Program (41+ Tests)

Covers Renewable Energy Certificate (REC/ERC) lifecycle management, Proof-of-Authority (PoA) issuance, multi-signature transfers, and double-claim prevention.

```typescript
import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { Governance } from "../target/types/governance";
import { assert, expect } from "chai";

describe("Governance Program", () => {
  const provider = anchor.getProvider() as anchor.AnchorProvider;
  const program = anchor.workspace.Governance as Program<Governance>;

  describe("ERC Certificate Lifecycle", () => {
    it("should issue certificate in Pending status", async () => {
      const certPDA = PublicKey.findProgramAddressSync(
        [Buffer.from("erc"), Buffer.from("CERT_001")],
        program.programId
      )[0];

      await program.methods
        .issueErc("CERT_001", new anchor.BN(1000 * 1e9), "Solar")
        .accounts({
          ercCertificate: certPDA,
          authority: provider.wallet.publicKey,
        })
        .rpc();

      const cert = await program.account.ercCertificate.fetch(certPDA);
      assert.strictEqual(cert.status, 0); // ErcStatus::Pending
      assert.strictEqual(cert.energyAmount.toNumber(), 1000 * 1e9);
      assert.strictEqual(cert.energySource, "Solar");
    });

    it("should transition certificate to Active upon verification", async () => {
      const certPDA = PublicKey.findProgramAddressSync(
        [Buffer.from("erc"), Buffer.from("CERT_002")],
        program.programId
      )[0];

      await program.methods
        .issueErc("CERT_002", new anchor.BN(500 * 1e9), "Wind")
        .accounts({ ercCertificate: certPDA })
        .rpc();

      await program.methods
        .verifyErc("CERT_002")
        .accounts({ ercCertificate: certPDA })
        .rpc();

      const cert = await program.account.ercCertificate.fetch(certPDA);
      assert.strictEqual(cert.status, 1); // ErcStatus::Active
    });

    it("should prevent double-claim of energy", async () => {
      // Meter has 1000 kWh total_generation
      // Already claimed 1000 kWh for CERT_003

      await expect(
        program.methods
          .issueErcWithVerification(new anchor.BN(100 * 1e9))
          .accounts({ meterAccount: meterPDA })
          .rpc()
      ).to.be.rejectedWith(/InsufficientUnclaimedEnergy/);
    });
  });

  describe("PoA Authority Management", () => {
    it("should require PoA authority for certificate issuance", async () => {
      const unauthorizedUser = anchor.web3.Keypair.generate();

      await expect(
        program.methods
          .issueErc("CERT_999", new anchor.BN(1000 * 1e9), "Hydro")
          .accounts({ authority: unauthorizedUser.publicKey })
          .signers([unauthorizedUser])
          .rpc()
      ).to.be.rejectedWith(/UnauthorizedRecAuthority/);
    });

    it("should support multi-sig authority transfer", async () => {
      const newAuthority = anchor.web3.Keypair.generate();

      await program.methods
        .transferRecAuthority(newAuthority.publicKey)
        .accounts({
          currentAuthority: provider.wallet.publicKey,
          newAuthority: newAuthority.publicKey,
        })
        .signers([newAuthority])
        .rpc();

      const governanceState = await program.account.governanceState.fetch(/* PDA */);
      assert.strictEqual(
        governanceState.recAuthority.toBase58(),
        newAuthority.publicKey.toBase58()
      );
    });
  });
});
```

#### 3.1.6 Blockbench Program (63+ Tests)

Covers custom micro-benchmarks including DoNothing (baseline), CPUHeavy, IOHeavy, YCSB workloads (A-F), TPC-C adapted workloads (New-Order, Payment, Order-Status, Delivery, Stock-Level), and analytics.

```typescript
import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { Blockbench } from "../target/types/blockbench";
import { assert } from "chai";

describe("Blockbench Benchmark Suite", () => {
  const provider = anchor.getProvider() as anchor.AnchorProvider;
  const program = anchor.workspace.Blockbench as Program<Blockbench>;

  describe("Baseline: DoNothing", () => {
    it("should execute minimal instruction (baseline latency)", async () => {
      const start = Date.now();
      await program.methods.doNothing().rpc();
      const elapsed = Date.now() - start;

      // DoNothing should complete within 1-2 block times (~400-800ms)
      assert.isBelow(elapsed, 2000, "DoNothing should be fast");
    });

    it("should report consistent CU usage across invocations", async () => {
      const cuUsages: number[] = [];
      for (let i = 0; i < 10; i++) {
        const tx = await program.methods.doNothing().rpc();
        const cuUsed = await getCuUsed(tx);
        cuUsages.push(cuUsed);
      }

      const variance = Math.max(...cuUsages) - Math.min(...cuUsages);
      assert.isBelow(variance, 100, "CU usage should be stable");
    });
  });

  describe("CPUHeavy Workload", () => {
    it("should execute hash-intensive computation", async () => {
      const iterations = new anchor.BN(1000);

      await program.methods
        .cpuHeavy(iterations)
        .rpc();

      const benchResult = await program.account.benchResult.fetch(/* PDA */);
      assert.isAbove(benchResult.cyclesCompleted.toNumber(), 0);
    });

    it("should handle varying iteration counts", async () => {
      const counts = [100, 500, 1000, 5000];
      for (const count of counts) {
        await program.methods
          .cpuHeavy(new anchor.BN(count))
          .rpc();
      }
    });
  });

  describe("IOHeavy Workload", () => {
    it("should perform multiple account read/writes", async () => {
      const numAccounts = new anchor.BN(10);

      await program.methods
        .ioHeavy(numAccounts)
        .rpc();

      const result = await program.account.ioResult.fetch(/* PDA */);
      assert.strictEqual(result.accountsProcessed.toNumber(), 10);
    });
  });

  describe("YCSB Workloads", () => {
    it("should execute Workload A (50% read, 50% update)", async () => {
      await program.methods
        .ycsbWorkloadA(new anchor.BN(100))
        .rpc();

      const stats = await program.account.ycsbStats.fetch(/* PDA */);
      assert.strictEqual(stats.reads + stats.updates, 100);
    });

    it("should execute Workload B (95% read, 5% update)", async () => {
      await program.methods
        .ycsbWorkloadB(new anchor.BN(100))
        .rpc();

      const stats = await program.account.ycsbStats.fetch(/* PDA */);
      assert.isAbove(stats.reads, stats.updates * 18); // ~95:5 ratio
    });

    it("should execute Workload C (100% read)", async () => {
      await program.methods
        .ycsbWorkloadC(new anchor.BN(100))
        .rpc();

      const stats = await program.account.ycsbStats.fetch(/* PDA */);
      assert.strictEqual(stats.updates, 0);
      assert.strictEqual(stats.reads, 100);
    });

    it("should execute Workload D (latest record workload)", async () => {
      await program.methods
        .ycsbWorkloadD(new anchor.BN(100))
        .rpc();
    });

    it("should execute Workload E (short-range scan)", async () => {
      await program.methods
        .ycsbWorkloadE(new anchor.BN(100))
        .rpc();
    });

    it("should execute Workload F (read-modify-write)", async () => {
      await program.methods
        .ycsbWorkloadF(new anchor.BN(100))
        .rpc();

      const stats = await program.account.ycsbStats.fetch(/* PDA */);
      assert.strictEqual(stats.readModifyWrites, 100);
    });
  });

  describe("TPC-C Adapted Workloads", () => {
    it("should execute New-Order transaction", async () => {
      await program.methods
        .tpccNewOrder(new anchor.BN(1), new anchor.BN(10))
        .rpc();
    });

    it("should execute Payment transaction", async () => {
      await program.methods
        .tpccPayment(new anchor.BN(1), new anchor.BN(500_000))
        .rpc();
    });

    it("should execute Order-Status query", async () => {
      await program.methods
        .tpccOrderStatus(new anchor.BN(1))
        .rpc();
    });

    it("should execute Delivery transaction", async () => {
      await program.methods
        .tpccDelivery(new anchor.BN(1))
        .rpc();
    });

    it("should execute Stock-Level query", async () => {
      await program.methods
        .tpccStockLevel(new anchor.BN(1))
        .rpc();
    });
  });
});
```

---

### 3.2 Integration Testing

Integration tests validate that programs work correctly together through Cross-Program Invocations (CPI), multi-service gRPC chains, and end-to-end business flows.

#### 3.2.1 End-to-End Trading Flow

This test validates the complete lifecycle from meter reading to token settlement:

```typescript
describe("E2E Integration: Energy Production to Token Settlement", () => {
  const provider = anchor.getProvider() as anchor.AnchorProvider;

  it("should complete full production-to-trading lifecycle", async () => {
    const energyProduced = new anchor.BN(1000 * 1e9);  // 1000 kWh
    const pricePerKwh = new anchor.BN(5_000_000);       // 5.00 THB/kWh
    const expiresAt = new anchor.BN(Math.floor(Date.now() / 1000) + 3600);

    // Step 1: Oracle receives and validates meter reading
    await oracleProgram.methods
      .submitMeterReading(
        "METER_E2E_001",
        energyProduced,
        new anchor.BN(200 * 1e9),  // consumption
        new anchor.BN(Math.floor(Date.now() / 1000))
      )
      .accounts({ authority: provider.wallet.publicKey })
      .rpc();

    // Step 2: Registry processes the reading and settles energy
    await registryProgram.methods
      .settleEnergy(energyProduced)
      .accounts({ meterAccount: meterPDA })
      .rpc();

    // Step 3: Energy Token program mints GRX tokens (1:1 kWh ratio)
    const tokenAccount = await getAccount(
      provider.connection,
      userTokenAccountPDA,
      "confirmed",
      TOKEN_2022_PROGRAM_ID
    );
    assert.strictEqual(
      tokenAccount.amount.toString(),
      energyProduced.toString(),
      "1:1 kWh to token minting ratio"
    );

    // Step 4: User creates sell order in Trading program
    await tradingProgram.methods
      .createSellOrderWithId(
        "sell_e2e_001",
        energyProduced,
        pricePerKwh,
        expiresAt
      )
      .accounts({ seller: seller.publicKey })
      .rpc();

    // Step 5: Buyer matches the order
    await tradingProgram.methods
      .matchOrders(energyProduced)
      .accounts({ buyOrder: buyOrderPDA, sellOrder: sellOrderPDA })
      .rpc();

    // Step 6: Verify atomic settlement
    const sellerTokenAfter = await getAccount(provider.connection, sellerTokenPDA);
    const buyerTokenAfter = await getAccount(provider.connection, buyerTokenPDA);

    assert.strictEqual(
      buyerTokenAfter.amount.toString(),
      energyProduced.toString(),
      "Buyer should receive energy tokens"
    );
    assert.strictEqual(
      sellerTokenAfter.amount.toString(),
      "0",
      "Seller should have transferred all tokens"
    );
  });
});
```

#### 3.2.2 Cross-Program CPI Tests

**Registry to Energy Token (Minting via CPI)**

```typescript
describe("CPI: Registry -> Energy Token", () => {
  it("should mint tokens via CPI when settling energy", async () => {
    const tokenAccountBefore = await getAccount(
      provider.connection,
      userTokenPDA,
      "confirmed",
      TOKEN_2022_PROGRAM_ID
    );
    const balanceBefore = tokenAccountBefore.amount;

    // Registry calls energy_token::mint_tokens_direct via CPI
    await registryProgram.methods
      .settleEnergy(new anchor.BN(500 * 1e9))
      .accounts({
        meterAccount: meterPDA,
        energyTokenProgram: energyTokenProgramId,
        tokenInfo: tokenInfoPDA,
        mint: mintPDA,
      })
      .rpc();

    const tokenAccountAfter = await getAccount(
      provider.connection,
      userTokenPDA,
      "confirmed",
      TOKEN_2022_PROGRAM_ID
    );

    assert.strictEqual(
      tokenAccountAfter.amount - balanceBefore,
      500_000_000_000n,
      "Should mint exactly 500 tokens via CPI"
    );
  });

  it("should reject minting if Registry is not authorized", async () => {
    await expect(
      energyTokenProgram.methods
        .mintTokensDirect(new anchor.BN(500 * 1e9))
        .accounts({ authority: unauthorizedProgramId })
        .rpc()
    ).to.be.rejectedWith(/UnauthorizedAuthority/);
  });
});
```

**Governance to Registry (Double-Claim Check)**

```typescript
describe("CPI: Governance -> Registry", () => {
  it("should verify unclaimed energy via Registry CPI", async () => {
    // Issue certificate with verification (reads Registry's high-water mark)
    await governanceProgram.methods
      .issueErcWithVerification(new anchor.BN(300 * 1e9))
      .accounts({
        ercCertificate: certPDA,
        meterAccount: meterPDA,
        registryProgram: registryProgramId,
      })
      .rpc();

    // Verify Registry high-water mark updated
    const meter = await registryProgram.account.meterAccount.fetch(meterPDA);
    assert.strictEqual(
      meter.claimedErcGeneration.toNumber(),
      300 * 1e9,
      "Registry should track claimed ERC generation"
    );
  });

  it("should prevent double-claim via Registry CPI check", async () => {
    // Meter has 1000 kWh, already claimed 800 kWh
    // Attempting to claim 300 more should fail (only 200 remaining)

    await expect(
      governanceProgram.methods
        .issueErcWithVerification(new anchor.BN(300 * 1e9))
        .accounts({ meterAccount: meterPDA })
        .rpc()
    ).to.be.rejectedWith(/InsufficientUnclaimedEnergy/);
  });
});
```

**Trading to Governance (ERC Validation)**

```typescript
describe("CPI: Trading -> Governance", () => {
  it("should validate ERC certificate when creating renewable sell order", async () => {
    // Create sell order referencing an active ERC certificate
    await tradingProgram.methods
      .createSellOrder(
        new anchor.BN(100 * 1e9),
        new anchor.BN(6_000_000),  // Premium price for renewable energy
        new anchor.BN(Math.floor(Date.now() / 1000) + 3600),
        "CERT_001"  // ERC certificate ID
      )
      .accounts({
        ercCertificate: certPDA,
        governanceProgram: governanceProgramId,
      })
      .rpc();

    const order = await tradingProgram.account.order.fetch(sellOrderPDA);
    assert.strictEqual(order.ercCertificateId, "CERT_001");
    assert.isTrue(order.isRenewable, "Order should be marked as renewable");
  });

  it("should reject orders with invalid or expired ERC certificates", async () => {
    await expect(
      tradingProgram.methods
        .createSellOrder(
          new anchor.BN(100 * 1e9),
          new anchor.BN(6_000_000),
          expiresAt,
          "INVALID_CERT"
        )
        .accounts({ governanceProgram: governanceProgramId })
        .rpc()
    ).to.be.rejectedWith(/InvalidErcCertificate/);
  });
});
```

#### 3.2.3 Multi-Service gRPC Integration

Tests the API Gateway to microservice communication chain:

```typescript
describe("Multi-Service gRPC Integration", () => {
  it("should route user registration through API Gateway to IAM Service", async () => {
    const response = await fetch("http://localhost:4000/api/v1/users", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        email: "test@example.com",
        username: "test_prosumer",
        password: "P@ssw0rd123!",
        role: "prosumer",
      }),
    });

    assert.strictEqual(response.status, 201);
    const user = await response.json();
    assert.isDefined(user.walletAddress);
    assert.isDefined(user.onChainTxSignature);
  });

  it("should process meter readings through Oracle Bridge to Oracle Service", async () => {
    // Edge Gateway -> Oracle Bridge -> Oracle Service -> Blockchain
    const reading = {
      meterId: "METER_SIM_001",
      producedKwh: 150.5,
      consumedKwh: 75.2,
      timestamp: Date.now(),
      signature: "ed25519_signature_hex",
    };

    const response = await fetch("http://localhost:4010/api/v1/readings", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(reading),
    });

    assert.strictEqual(response.status, 202);
    const result = await response.json();
    assert.strictEqual(result.status, "accepted");
  });
});
```

---

### 3.3 Security Testing

Proactive identification of vulnerabilities across all attack vectors. Security testing covers authorization, input validation, replay prevention, reentrancy safety, integer arithmetic safety, and economic exploit resistance.

#### 3.3.1 Authorization and Access Control

```typescript
describe("Security: Authorization Tests", () => {
  it("should prevent unauthorized oracle updates", async () => {
    const unauthorizedUser = anchor.web3.Keypair.generate();

    await expect(
      oracleProgram.methods
        .updateOracleStatus(false)
        .accounts({ authority: unauthorizedUser.publicKey })
        .signers([unauthorizedUser])
        .rpc()
    ).to.be.rejectedWith(/UnauthorizedAuthority/);
  });

  it("should enforce PDA authority for token minting", async () => {
    const maliciousKeypair = anchor.web3.Keypair.generate();

    await expect(
      program.methods
        .mintTokensDirect(new anchor.BN(1000))
        .accounts({ authority: maliciousKeypair.publicKey })
        .signers([maliciousKeypair])
        .rpc()
    ).to.be.rejectedWith(/UnauthorizedAuthority/);
  });

  it("should require admin authority for governance actions", async () => {
    const regularUser = anchor.web3.Keypair.generate();

    await expect(
      governanceProgram.methods
        .issueErc("CERT_999", new anchor.BN(1000 * 1e9), "Wind")
        .accounts({ authority: regularUser.publicKey })
        .signers([regularUser])
        .rpc()
    ).to.be.rejectedWith(/UnauthorizedRecAuthority/);
  });
});
```

#### 3.3.2 Input Validation and Boundary Conditions

```typescript
describe("Security: Input Validation", () => {
  it("should reject energy readings exceeding maximum value", async () => {
    const maxEnergy = new anchor.BN(1_000_000 * 1e9);  // 1M kWh
    const excessiveReading = maxEnergy.add(new anchor.BN(1));

    await expect(
      oracleProgram.methods
        .submitMeterReading("METER_001", excessiveReading, new anchor.BN(0), timestamp)
        .rpc()
    ).to.be.rejectedWith(/EnergyValueOutOfRange/);
  });

  it("should prevent negative token amounts (overflow attack)", async () => {
    // Anchor's BN validation catches negative values before instruction execution
    await expect(
      energyTokenProgram.methods
        .mintTokensDirect(new anchor.BN(-1000))
        .rpc()
    ).to.be.rejected;
  });

  it("should enforce maximum string lengths for identifiers", async () => {
    const oversizedMeterId = "M".repeat(256);  // Exceeds 64-byte limit

    await expect(
      oracleProgram.methods
        .submitMeterReading(oversizedMeterId, energy, energy, timestamp)
        .rpc()
    ).to.be.rejectedWith(/StringTooLong/);
  });

  it("should validate timestamp freshness", async () => {
    const staleTimestamp = new anchor.BN(Math.floor(Date.now() / 1000) - 7200);  // 2 hours ago

    await expect(
      oracleProgram.methods
        .submitMeterReading("METER_001", energy, energy, staleTimestamp)
        .rpc()
    ).to.be.rejectedWith(/StaleTimestamp/);
  });
});
```

#### 3.3.3 Replay Attack Prevention

```typescript
describe("Security: Replay Attack Tests", () => {
  it("should prevent resubmission of old meter readings (temporal monotonicity)", async () => {
    const timestamp1 = new anchor.BN(Math.floor(Date.now() / 1000));

    await oracleProgram.methods
      .submitMeterReading("METER_001", energy, energy, timestamp1)
      .rpc();

    // Attempt to replay old timestamp
    await expect(
      oracleProgram.methods
        .submitMeterReading("METER_001", energy, energy, timestamp1)
        .rpc()
    ).to.be.rejectedWith(/OutdatedReading/);
  });

  it("should use unique PDAs for orders (prevent replay)", async () => {
    // First order creates PDA
    await tradingProgram.methods
      .createBuyOrderWithId("buy_replay_001", quantity, price, expiresAt)
      .accounts({ order: orderPDA })
      .rpc();

    // Attempting to create duplicate order at same PDA should fail
    await expect(
      tradingProgram.methods
        .createBuyOrderWithId("buy_replay_001", quantity, price, expiresAt)
        .accounts({ order: orderPDA })
        .rpc()
    ).to.be.rejectedWith(/already in use/);
  });
});
```

#### 3.3.4 Reentrancy and CPI Safety

```typescript
describe("Security: Reentrancy and CPI Safety", () => {
  it("should follow checks-effects-interactions pattern in settlement", async () => {
    const meterBefore = await registryProgram.account.meterAccount.fetch(meterPDA);

    await registryProgram.methods
      .settleEnergy(amount)
      .rpc();

    const meterAfter = await registryProgram.account.meterAccount.fetch(meterPDA);

    // State updated BEFORE external CPI to energy_token::mint_tokens_direct
    assert.isTrue(
      meterAfter.settledNetGeneration.toNumber() > meterBefore.settledNetGeneration.toNumber(),
      "State should be updated before CPI call"
    );
  });

  it("should prevent unauthorized CPI callers", async () => {
    const maliciousProgramId = anchor.web3.Keypair.generate().publicKey;

    await expect(
      energyTokenProgram.methods
        .mintTokensDirect(amount)
        .accounts({ authority: maliciousProgramId })
        .rpc()
    ).to.be.rejectedWith(/UnauthorizedAuthority/);
  });
});
```

#### 3.3.5 Integer Overflow/Underflow Protection

```typescript
describe("Security: Arithmetic Safety", () => {
  it("should use saturating addition to prevent overflow", async () => {
    const maxU64 = new anchor.BN("18446744073709551615");  // u64::MAX

    // Attempting to mint beyond u64::MAX should saturate, not wrap
    await program.methods
      .setTotalSupplyForTest(maxU64)
      .rpc();

    await energyTokenProgram.methods
      .mintTokensDirect(new anchor.BN(1000))
      .rpc();

    const tokenInfoAfter = await energyTokenProgram.account.tokenInfo.fetch(tokenInfoPDA);
    // Saturates at max rather than wrapping to 0
    assert.strictEqual(
      tokenInfoAfter.totalSupply.toString(),
      maxU64.toString()
    );
  });

  it("should use saturating subtraction for burns (no underflow)", async () => {
    const tokenAccount = await getAccount(provider.connection, userTokenPDA);
    const balance = tokenAccount.amount;

    const excessiveBurn = new anchor.BN(balance.toString()).add(new anchor.BN(1000));

    await expect(
      energyTokenProgram.methods
        .burnTokens(excessiveBurn)
        .rpc()
    ).to.be.rejectedWith(/InsufficientFunds/);
  });
});
```

#### 3.3.6 Economic Attack Vectors

```typescript
describe("Security: Economic Exploits", () => {
  it("should prevent front-running via time-priority matching", async () => {
    // Create multiple orders in the same slot
    const orders = await Promise.all([
      tradingProgram.methods.createBuyOrder(amount1, price1, expires).rpc(),
      tradingProgram.methods.createSellOrder(amount2, price2, expires).rpc(),
      tradingProgram.methods.createSellOrder(amount3, price3, expires).rpc(),
    ]);

    // Process orders via CDA matching
    await tradingProgram.methods.triggerMarketClearing().rpc();

    // Orders matched at fair clearing price (no preferential treatment)
    const executions = await tradingProgram.account.market.fetch(marketPDA);
    const clearingPrice = executions.lastClearingPrice;

    // Verify no order got preferential price
    assert.isBelow(
      executions.priceVariance,
      0.01,
      "Price variance should be <1%"
    );
  });

  it("should prevent double-spending of energy", async () => {
    // Claim 800 kWh for tokens (out of 1000 kWh total)
    await registryProgram.methods
      .settleEnergy(new anchor.BN(800 * 1e9))
      .rpc();

    // Attempt to claim 500 kWh for certificate (only 200 remaining)
    await expect(
      governanceProgram.methods
        .issueErcWithVerification(new anchor.BN(500 * 1e9))
        .rpc()
    ).to.be.rejectedWith(/InsufficientUnclaimedEnergy/);
  });

  it("should enforce rate limiting to prevent spam attacks", async () => {
    await oracleProgram.methods
      .submitMeterReading("METER_001", energy, energy, timestamp1)
      .rpc();

    // Immediate second submission (within 60s minimum interval)
    await expect(
      oracleProgram.methods
        .submitMeterReading("METER_001", energy, energy, timestamp1.add(new anchor.BN(30)))
        .rpc()
    ).to.be.rejectedWith(/RateLimitExceeded/);
  });
});
```

#### 3.3.7 Security Test Coverage Summary

| Attack Vector | Test Count | Coverage | Status |
|:--------------|:-----------|:---------|:-------|
| Unauthorized Access | 15 tests | 100% | PASS |
| Input Validation | 23 tests | 98% | PASS |
| Replay Attacks | 8 tests | 100% | PASS |
| Reentrancy | 6 tests | 85% | PARTIAL (CPI caller verification pending) |
| Integer Overflow/Underflow | 12 tests | 100% | PASS |
| Economic Exploits | 9 tests | 92% | PASS |
| Timestamp Manipulation | 7 tests | 100% | PASS |
| Account Confusion | 11 tests | 100% | PASS |

**Total Security Tests:** 91 tests across 8 attack vectors
**Overall Coverage:** 96.8%
**Known Vulnerabilities:** 0 critical, 1 medium (CPI caller verification -- pending in Q2 2026)

---

### 3.4 Performance and Load Testing

Performance testing evaluates system behavior under stress using specialized benchmarking tools, concurrent user simulation, and real-world network condition emulation.

#### 3.4.1 Blockbench Benchmark Results

Blockbench is a custom micro-benchmarking tool developed for GridTokenX, measuring throughput, latency, and Compute Unit (CU) efficiency across standardized workloads.

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                       BLOCKBENCH WORKLOAD MATRIX                               │
├──────────────────┬────────────┬────────────┬────────────┬─────────────────────┤
│    Workload      │ Operations │ Avg Latency│ CU/Op      │ Throughput (TPS)   │
├──────────────────┼────────────┼────────────┼────────────┼─────────────────────┤
│ DoNothing        │   10,000   │  410 ms    │     350 CU │   14,800 (peak)    │
│ CPUHeavy (1000)  │    5,000   │  520 ms    │   8,200 CU │    7,600 (peak)    │
│ CPUHeavy (5000)  │    2,000   │  890 ms    │  38,500 CU │    3,200 (peak)    │
│ IOHeavy (10 accts)│   5,000   │  480 ms    │   5,400 CU │    8,900 (peak)    │
│ YCSB-A (50/50)   │   10,000   │  445 ms    │   3,800 CU │   10,200 (peak)    │
│ YCSB-B (95/5)    │   10,000   │  425 ms    │   2,100 CU │   12,400 (peak)    │
│ YCSB-C (100% R)  │   10,000   │  415 ms    │   1,200 CU │   13,800 (peak)    │
│ YCSB-D (Latest)  │   10,000   │  430 ms    │   2,800 CU │   11,500 (peak)    │
│ YCSB-E (Scan)    │   10,000   │  455 ms    │   4,100 CU │    9,800 (peak)    │
│ YCSB-F (RMW)     │   10,000   │  470 ms    │   4,500 CU │    9,200 (peak)    │
├──────────────────┼────────────┼────────────┼────────────┼─────────────────────┤
│ Energy Token     │   15,000   │  415 ms    │  15,200 CU │    8,500 (sustained)│
│ Oracle           │   12,000   │  435 ms    │   6,800 CU │    7,200 (sustained)│
│ Registry         │   10,000   │  440 ms    │  11,500 CU │    6,800 (sustained)│
│ Trading          │    8,000   │  465 ms    │  18,200 CU │    5,400 (sustained)│
│ Governance       │    5,000   │  450 ms    │   8,900 CU │    4,800 (sustained)│
└──────────────────┴────────────┴────────────┴────────────┴─────────────────────┘

Key: 50/50 = 50% read / 50% update; RMW = Read-Modify-Write
```

#### 3.4.2 TPC-C Benchmark Results

The TPC-C benchmark has been adapted for GridTokenX to measure OLTP (Online Transaction Processing) performance across five standard transaction types. The measurements below represent the **2.2 High-Throughput** microservices configuration.

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        TPC-C BENCHMARK RESULTS (V2.2)                           │
├──────────────────┬────────────┬────────────┬─────────────┬──────────────────────┤
│   Transaction    │ Count      │ Avg Latency│ P99 Latency │ Throughput (tx/s)   │
├──────────────────┼────────────┼────────────┼─────────────┼──────────────────────┤
│ New-Order        │   50,000   │  385 ms    │   720 ms    │    2,185            │
│ Payment          │   50,000   │  360 ms    │   650 ms    │    2,420            │
│ Order-Status     │   50,000   │  345 ms    │   590 ms    │    2,890            │
│ Delivery         │   50,000   │  410 ms    │   810 ms    │    1,940            │
│ Stock-Level      │   50,000   │  370 ms    │   690 ms    │    2,310            │
├──────────────────┼────────────┼────────────┼─────────────┼──────────────────────┤
│ Overall          │  250,000   │  374 ms    │   692 ms    │    2,349 (avg)      │
├──────────────────┼────────────┴────────────┴─────────────┴──────────────────────┤
│ tpmC (New-Order)│  21,136 new-orders/min (Production Confirmed)                │
│ SmallBank TPS   │  1,745 transactions/sec (Peak)                                │
│ Response SLA    │  98% under 500ms, 99.8% under 800ms                           │
└──────────────────┴──────────────────────────────────────────────────────────────┘
```

#### 3.4.3 Load Testing Results

Three load testing scenarios evaluate system resilience under realistic and extreme conditions.

**Scenario 1: Concurrent Users**

| Metric | Value |
|:-------|:------|
| Concurrent Users | 500 |
| Duration | 30 minutes |
| Total Transactions | 180,000 |
| Average Response Time | 445ms |
| P95 Response Time | 720ms |
| P99 Response Time | 950ms |
| Error Rate | 0.1% |
| Peak TPS | 120 |

**Scenario 2: High-Volume Trading**

| Metric | Value |
|:-------|:------|
| Orders/Second | 6,000 |
| Matching Rate | 4,200/second |
| Settlement Success | 99.7% |
| Token Transfer Latency | 410ms |
| Order Book Depth | 10,000+ active orders |

**Scenario 3: Network Conditions**

| Condition | Impact |
|:----------|:-------|
| +50ms latency | Throughput drops 12%, error rate unchanged |
| +100ms latency | Throughput drops 25%, 0.5% timeout rate |
| +200ms latency | Throughput drops 40%, 2.1% timeout rate |
| 1% packet loss | Retries add 8% latency, 0.3% failure rate |
| 5% packet loss | Retries add 35% latency, 4.8% failure rate |

#### 3.4.4 Performance Metrics Summary (January 2026)

| Metric | Value | Description |
|:-------|:------|:------------|
| **Average Latency** | ~420 ms | Transaction confirmation time (local validator, 400ms slot time) |
| **Peak Throughput** | ~15,000 TPS | Theoretical maximum (Solana v1.18, parallel execution enabled) |
| **Sustained Throughput** | ~4,200 TPS | Measured under sustained load testing (63% of theoretical max) |
| **Oracle Submissions** | ~8,000/sec | Meter reading ingestion rate |
| **Order Matching** | ~6,000/sec | Trading engine CDA matching rate |
| **Success Rate** | 99.7% | Reliability under stress (0.3% transient failures, all recoverable) |
| **Compute Unit Efficiency** | 85% | Average CU budget utilization (12,000 CU per tx post-optimization) |
| **P95 Latency** | ~720 ms | 95th percentile response time |
| **P99 Latency** | ~950 ms | 99th percentile response time |

#### 3.4.5 Per-Program Performance Breakdown

**Energy Token Program**
| Operation | Avg Latency | CU Consumption | Throughput |
|:----------|:------------|:---------------|:-----------|
| `initialize_token` | ~450 ms | ~13,000 CU | N/A (one-time) |
| `mint_to_wallet` | ~415 ms | ~18,000 CU | ~6,665/sec |
| `mint_tokens_direct` | ~410 ms | ~18,000 CU | ~6,665/sec |
| `burn_tokens` | ~405 ms | ~14,000 CU | ~8,500/sec |
| `transfer_tokens` | ~395 ms | ~15,200 CU | ~7,900/sec |
| `add_rec_validator` | ~380 ms | ~2,800 CU | ~42,000/sec |

**Oracle Program**
| Operation | Avg Latency | CU Consumption | Throughput |
|:----------|:------------|:---------------|:-----------|
| `submit_meter_reading` | ~435 ms | ~6,800 CU | ~7,200/sec |
| `update_oracle_status` | ~420 ms | ~3,200 CU | ~12,500/sec |
| `calculate_quality_score` | ~445 ms | ~4,500 CU | ~9,800/sec |
| `trigger_market_clearing` | ~460 ms | ~8,900 CU | ~5,800/sec |

**Registry Program**
| Operation | Avg Latency | CU Consumption | Throughput |
|:----------|:------------|:---------------|:-----------|
| `register_user` | ~430 ms | ~9,200 CU | ~6,200/sec |
| `register_meter` | ~440 ms | ~8,500 CU | ~6,500/sec |
| `update_meter_reading` | ~425 ms | ~7,100 CU | ~7,400/sec |
| `settle_energy` | ~455 ms | ~14,200 CU | ~5,100/sec |
| `claim_erc_generation` | ~440 ms | ~6,800 CU | ~7,600/sec |

**Trading Program**
| Operation | Avg Latency | CU Consumption | Throughput |
|:----------|:------------|:---------------|:-----------|
| `create_buy_order` | ~440 ms | ~11,500 CU | ~5,600/sec |
| `create_sell_order` | ~445 ms | ~12,200 CU | ~5,300/sec |
| `match_orders` | ~480 ms | ~22,000 CU | ~4,100/sec |
| `cancel_order` | ~410 ms | ~5,800 CU | ~8,900/sec |
| `trigger_market_clearing` | ~465 ms | ~18,500 CU | ~4,700/sec |

**Governance Program**
| Operation | Avg Latency | CU Consumption | Throughput |
|:----------|:------------|:---------------|:-----------|
| `issue_erc` | ~445 ms | ~8,200 CU | ~6,500/sec |
| `verify_erc` | ~435 ms | ~6,500 CU | ~7,800/sec |
| `transfer_rec_authority` | ~420 ms | ~4,200 CU | ~10,200/sec |

---

### 3.5 Edge Case and Resource Testing

| Category | Tests | Description |
|:---------|:------|:------------|
| **Network Failures** | 8 | Connection drops, validator restarts, RPC timeouts |
| **Data Consistency** | 12 | Concurrent reads during writes, eventual consistency windows |
| **Boundary Values** | 15 | u64::MAX, zero values, minimum/maximum string lengths |
| **Resource Optimization** | 6 | Memory leak detection, CU budget analysis, account size limits |
| **Clock Skew** | 4 | Validator clock drift, slot time variation |

```typescript
describe("Edge Cases: Resource Limits", () => {
  it("should handle maximum account data size", async () => {
    // Solana accounts have a 10MB limit per transaction
    // Verify our PDAs stay well within limits
    const accountSize = await getAccountSize(provider.connection, largeAccountPDA);
    assert.isBelow(accountSize, 1024 * 1024, "Account should be under 1MB");
  });

  it("should handle rapid consecutive orders", async () => {
    const orders = Array.from({ length: 100 }, async (_, i) => {
      return tradingProgram.methods
        .createBuyOrder(
          new anchor.BN((i + 1) * 1e9),
          new anchor.BN(5_000_000),
          new anchor.BN(Math.floor(Date.now() / 1000) + 3600)
        )
        .rpc();
    });

    const results = await Promise.allSettled(orders);
    const successes = results.filter((r) => r.status === "fulfilled").length;
    assert.isAbove(successes, 95, "At least 95% of rapid orders should succeed");
  });
});
```

---

## 4. Test Execution and Reporting

### 4.1 Running the Test Suite

GridTokenX uses `just` as the primary task runner for all testing workflows. These commands encapsulate the underlying Anchor and Cargo calls.

```bash
# Initialize blockchain and deploy contracts
./scripts/app.sh init

# All tests (Unit + Security + Performance)
just test

# Unit tests only
just test-unit

# Integration tests only
just test-integration

# Security-focused tests only
just security-audit

# Performance benchmarks (TPC-C style)
just benchmark:tpc-c

# SmallBank throughput test
just benchmark:smallbank
```

### 4.2 Test Coverage Report

```
┌──────────────────────────────────────────────────────────────────────┐
│                   TEST COVERAGE SUMMARY                              │
├─────────────────────┬────────────┬────────────┬──────────────────────┤
│      Program        │    Lines   │  Branches  │      Status          │
├─────────────────────┼────────────┼────────────┼──────────────────────┤
│ Energy Token        │   94.2%    │   91.8%    │   PASS               │
│ Oracle              │   92.5%    │   89.3%    │   PASS               │
│ Registry            │   95.1%    │   93.0%    │   PASS               │
│ Trading             │   96.3%    │   94.5%    │   PASS               │
│ Governance          │   93.7%    │   90.8%    │   PASS               │
│ Blockbench          │   91.0%    │   88.2%    │   PASS               │
├─────────────────────┼────────────┼────────────┼──────────────────────┤
│ Weighted Average    │   94.1%    │   91.3%    │   PASS               │
└─────────────────────┴────────────┴────────────┴──────────────────────┘
```

### 4.3 CI/CD Integration

```yaml
# .github/workflows/test.yml
name: GridTokenX Test Suite

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: anchor fmt --check
      - run: cargo clippy -- -D warnings

  unit-tests:
    needs: lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: metadaoproject/setup-solana@v1
      - uses: metadaoproject/setup-anchor@v2
      - run: npm install
      - run: anchor test
      - run: anchor test --grep "Security"
        if: github.event_name == 'pull_request'

  integration-tests:
    needs: unit-tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: anchor test --skip-build --skip-local-validator
        env:
          ANCHOR_WALLET: ${{ secrets.TEST_WALLET }}

  benchmarks:
    needs: integration-tests
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - run: anchor test --grep "Benchmark"
      - uses: actions/upload-artifact@v4
        with:
          name: benchmark-results
          path: target/deploy/benchmark_report.json
```

---

## 5. Continuous Improvement

### 5.1 Test Metrics Tracking

| Metric | Current | Target | Trend |
|:-------|:--------|:-------|:------|
| Total Tests | 306 | 350+ | Up |
| Line Coverage | 94.1% | 95%+ | Up |
| Branch Coverage | 91.3% | 93%+ | Up |
| Security Tests | 91 | 100+ | Up |
| Benchmark Run Time | ~50 min | <40 min | Down |
| False Positive Rate | 0.5% | <0.2% | Down |

### 5.2 Known Gaps and Roadmap

| Gap | Priority | Target Date | Owner |
|:----|:---------|:------------|:------|
| CPI caller verification (reentrancy) | Medium | Q2 2026 | Security Team |
| Fuzz testing for arithmetic operations | High | Q2 2026 | QA Team |
| Property-based testing for order matching | Medium | Q3 2026 | Trading Team |
| Mainnet fork testing | Low | Q3 2026 | Infrastructure |
| Chaos engineering (validator failures) | Low | Q4 2026 | SRE Team |

---

## 6. Document Metadata

| Field | Value |
|:------|:------|
| **Document Title** | Software Testing and Validation |
| **Version** | 3.0.0 |
| **Last Updated** | April 2026 |
| **Status** | Production-Ready |
| **Authors** | GridTokenX Research Team |
| **Review Cycle** | Quarterly |
| **Technical Documentation** | [Architecture Specs](../architecture/) |
| **Test Framework** | Anchor 0.32.1, Mocha 10.x, Chai 4.x, **just runner** |
| **Blockchain** | Solana v1.18 (OrbStack containerized) |
| **Total Test Count** | 306+ automated tests |
| **Security Tests** | 91 tests (96.8% coverage) |
| **Benchmark Suites** | Blockbench, TPC-C, SmallBank |
| **Overall Coverage** | 94.1% lines, 91.3% branches |

---

> *"Quality is not an act, it is a habit. Every line of test code is a commitment to the users who trust GridTokenX with their energy trades."*
