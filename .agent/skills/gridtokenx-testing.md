---
name: gridtokenx-testing
description: Comprehensive testing strategy for GridTokenX. Covers Rust unit/integration tests, Anchor program tests, e2e trading scenarios, load testing, and CI/CD integration.
user-invocable: true
---

# GridTokenX Testing Skill

## What this Skill is for

Use this Skill when the user asks for:

- **Writing tests** for Rust services, Anchor programs, or frontend
- **Running test suites** (unit, integration, e2e, load)
- **Test infrastructure** setup and configuration
- **CI/CD integration** for automated testing
- **Test coverage** analysis and improvement
- **Mocking and fixtures** for isolated testing
- **Performance testing** and benchmarking

## Testing pyramid

```
                    ┌─────────┐
                   │   E2E   │  ← Few, critical user journeys
                  ├─────────────┤
                 │  Integration  │ ← Service interactions
                ├───────────────────┤
               │      Unit Tests     │ ← Many, fast, isolated
              └───────────────────────┘
```

## Test categories

### 1. Unit Tests (Rust)

Fast, isolated tests for individual functions/modules:

```rust
// gridtokenx-api/src/services/user_service.rs

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_validate_email_format() {
        assert!(is_valid_email("user@example.com"));
        assert!(!is_valid_email("invalid-email"));
        assert!(!is_valid_email("missing@domain"));
    }

    #[tokio::test]
    async fn test_create_user_success() {
        let pool = create_test_pool().await;
        let result = create_user(&pool, "test@example.com", "password123").await;
        
        assert!(result.is_ok());
        let user = result.unwrap();
        assert_eq!(user.email, "test@example.com");
    }
}
```

**Run unit tests:**
```bash
# All Rust tests
cargo test

# Specific package
cargo test -p gridtokenx-api

# Specific test
cargo test test_validate_email_format

# With output
cargo test -- --nocapture
```

### 2. Integration Tests (Rust)

Test service interactions with real dependencies:

```rust
// gridtokenx-api/tests/integration/user_tests.rs

use gridtokenx_api::{config::Config, db::create_pool};
use sqlx::PgPool;
use uuid::Uuid;

async fn setup_test_environment() -> PgPool {
    let config = Config::from_env().unwrap();
    create_pool(&config.database_url).await.unwrap()
}

#[tokio::test]
async fn test_user_registration_flow() {
    let pool = setup_test_environment().await;
    
    // Register user
    let user = register_user(&pool, "test@example.com", "password").await.unwrap();
    
    // Verify email
    verify_email(&pool, user.id).await.unwrap();
    
    // Login
    let token = login(&pool, "test@example.com", "password").await.unwrap();
    
    assert!(!token.is_empty());
}
```

**Run integration tests:**
```bash
# Integration tests only
cargo test --test '*'

# Specific integration test
cargo test --test user_tests

# With database
docker-compose up -d postgres
cargo test --test '*' -- --ignored
```

### 3. Anchor Program Tests

Test smart contracts with Anchor framework:

```typescript
// gridtokenx-anchor/tests/registry.ts

import * as anchor from "@coral-xyz/anchor";
import { assert } from "chai";

describe("registry", () => {
  const provider = anchor.AnchorProvider.env();
  const program = anchor.workspace.Registry;

  it("Initializes registry successfully", async () => {
    const [registryPda] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("registry")],
      program.programId
    );

    await program.methods
      .initialize()
      .accounts({
        registry: registryPda,
        signer: provider.publicKey,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .rpc();

    const registry = await program.account.registry.fetch(registryPda);
    assert.ok(registry.authority.equals(provider.publicKey));
  });

  it("Fails with invalid authority", async () => {
    const [registryPda] = anchor.web3.PublicKey.findProgramAddressSync(
      [Buffer.from("registry")],
      program.programId
    );

    try {
      await program.methods
        .updateAuthority()
        .accounts({ registry: registryPda })
        .signers([otherWallet])
        .rpc();
      assert.fail("Should have failed");
    } catch (err) {
      assert.include(err.toString(), "ConstraintOwner");
    }
  });
});
```

**Run Anchor tests:**
```bash
cd gridtokenx-anchor

# Build and test
anchor test

# Skip build
anchor test --skip-build

# With coverage
anchor test --coverage

# Specific test file
anchor test tests/trading.ts
```

### 4. End-to-End Tests

Full system tests simulating real user scenarios:

```bash
#!/bin/bash
# gridtokenx-api/tests/scripts/test_e2e_trading.sh

# 1. Register users
curl -X POST $API_URL/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"email":"buyer@example.com","password":"pass123"}'

curl -X POST $API_URL/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"email":"seller@example.com","password":"pass123"}'

# 2. Create trading order
curl -X POST $API_URL/api/v1/orders \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"side":"buy","energy_amount":100,"price":0.15}'

# 3. Match order
curl -X POST $API_URL/api/v1/orders/match \
  -H "Authorization: Bearer $SELLER_TOKEN" \
  -d '{"order_id":"ORDER_ID"}'

# 4. Verify settlement
curl -X GET $API_URL/api/v1/orders/ORDER_ID \
  -H "Authorization: Bearer $TOKEN"
```

**Run e2e tests:**
```bash
# Start full platform
./scripts/app.sh start

# Run e2e tests
./gridtokenx-api/tests/scripts/test_e2e_trading.sh
./gridtokenx-api/tests/scripts/test_settlement_p2p.sh
./gridtokenx-api/tests/scripts/test_village_scenario.sh
```

### 5. Load Tests

Performance and throughput testing:

```bash
#!/bin/bash
# gridtokenx-api/tests/scripts/test_hft_throughput.sh

API_URL="http://localhost:4000"
TOKEN="your-auth-token"
CONCURRENT=10
REQUESTS=1000

echo "Running HFT throughput test..."
echo "Concurrent users: $CONCURRENT"
echo "Total requests: $REQUESTS"

# Using wrk or hey for load testing
wrk -t$CONCURRENT -c$CONCURRENT -d30s \
  -H "Authorization: Bearer $TOKEN" \
  "$API_URL/api/v1/orders"
```

**Run load tests:**
```bash
# High frequency trading test
./gridtokenx-api/tests/scripts/test_hft_throughput.sh

# Multi-user scenario
./gridtokenx-api/tests/scripts/test_hft_multi_user.sh

# Load test with 1000 users
./gridtokenx-api/tests/scripts/test_load_1000.sh
```

## Test infrastructure

### Test Database Setup

```rust
// gridtokenx-api/tests/common/db.rs

use sqlx::{PgPool, postgres::PgPoolOptions};

pub async fn create_test_pool() -> PgPool {
    let database_url = std::env::var("TEST_DATABASE_URL")
        .unwrap_or_else(|_| "postgresql://gridtokenx_user:gridtokenx_password@localhost:5434/gridtokenx_test".to_string());
    
    PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await
        .expect("Failed to create test pool")
}

pub async fn cleanup_database(pool: &PgPool) {
    sqlx::query("TRUNCATE TABLE users CASCADE;")
        .execute(pool)
        .await
        .unwrap();
    
    sqlx::query("TRUNCATE TABLE trading_orders CASCADE;")
        .execute(pool)
        .await
        .unwrap();
}
```

### Test Fixtures

```rust
// gridtokenx-api/tests/fixtures/users.rs

use uuid::Uuid;

pub struct TestUser {
    pub id: Uuid,
    pub email: String,
    pub token: String,
}

pub async fn create_test_user(pool: &sqlx::PgPool) -> TestUser {
    let email = format!("test_{}@example.com", Uuid::new_v4());
    let password = "TestPassword123!";
    
    let user = register_user(pool, &email, password).await.unwrap();
    let token = login(pool, &email, password).await.unwrap();
    
    TestUser {
        id: user.id,
        email,
        token,
    }
}
```

### Mock Services

```rust
// gridtokenx-api/tests/mocks/blockchain.rs

use gridtokenx_api::services::BlockchainService;

pub struct MockBlockchainService {
    pub should_succeed: bool,
    pub mock_balance: u64,
}

#[async_trait]
impl BlockchainService for MockBlockchainService {
    async fn get_balance(&self, _address: &str) -> Result<u64, Error> {
        if self.should_succeed {
            Ok(self.mock_balance)
        } else {
            Err(Error::BlockchainError("Mock failure"))
        }
    }
    
    async fn transfer_tokens(&self, _from: &str, _to: &str, _amount: u64) -> Result<String, Error> {
        Ok("mock_tx_signature".to_string())
    }
}
```

## Coverage analysis

### Rust Coverage

```bash
# Install cargo-tarpaulin
cargo install cargo-tarpaulin

# Run with coverage
cargo tarpaulin --out Html --output-dir coverage

# View coverage report
open coverage/tarpaulin-report.html
```

### TypeScript Coverage

```bash
cd gridtokenx-anchor

# Run tests with coverage
anchor test --coverage

# View coverage report
open coverage/lcov-report/index.html
```

## CI/CD Integration

### GitHub Actions Example

```yaml
# .github/workflows/test.yml

name: Tests

on: [push, pull_request]

jobs:
  test-rust:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:17
        env:
          POSTGRES_PASSWORD: gridtokenx_password
        ports:
          - 5434:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Rust
        uses: dtolnay/rust-action@stable
      
      - name: Install Solana
        uses: metadaoproject/setup-solana@v1
      
      - name: Install Anchor
        uses: metadaoproject/setup-anchor@v1
      
      - name: Run Rust tests
        run: |
          cargo test
          cargo test --test '*' -- --ignored
        env:
          TEST_DATABASE_URL: postgresql://postgres:gridtokenx_password@localhost:5434/gridtokenx_test
      
      - name: Run Anchor tests
        run: |
          cd gridtokenx-anchor
          anchor test
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

## Test scripts reference

| Script | Purpose |
|--------|---------|
| `test_api_integration.sh` | API endpoint integration |
| `test_e2e_trading.sh` | Complete trading flow |
| `test_dca_api.sh` | Dollar-cost averaging |
| `test_settlement_p2p.sh` | P2P settlement |
| `test_zone_sharding.sh` | Zone-based sharding |
| `test_hft_multi_user.sh` | Multi-user HFT |
| `test_hft_throughput.sh` | Throughput benchmark |
| `test_load_1000.sh` | Load test with 1000 users |
| `test_market_admin.sh` | Market administration |
| `test_village_scenario.sh` | Village microgrid |
| `simulate_grid_readings.sh` | Smart meter simulation |
| `register_55_users.sh` | Bulk user registration |

## Best practices

### Unit Tests
- Keep tests fast (< 100ms each)
- Test one thing per test
- Use descriptive test names
- Mock external dependencies
- Test edge cases and errors

### Integration Tests
- Use test-specific database
- Clean up after tests
- Test real service interactions
- Include error scenarios
- Run in CI/CD pipeline

### E2E Tests
- Focus on critical user journeys
- Keep tests deterministic
- Use realistic test data
- Include performance metrics
- Run on staging environment

### Load Tests
- Start with baseline measurements
- Test under expected load
- Test beyond expected load (stress)
- Monitor resource usage
- Identify bottlenecks

## Common patterns

### Test Builder Pattern

```rust
pub struct OrderBuilder {
    side: String,
    energy_amount: f64,
    price: f64,
    user_id: Uuid,
}

impl OrderBuilder {
    pub fn new() -> Self {
        Self {
            side: "buy".to_string(),
            energy_amount: 100.0,
            price: 0.15,
            user_id: Uuid::nil(),
        }
    }
    
    pub fn with_side(mut self, side: &str) -> Self {
        self.side = side.to_string();
        self
    }
    
    pub fn with_amount(mut self, amount: f64) -> Self {
        self.energy_amount = amount;
        self
    }
    
    pub fn build(self, pool: &PgPool) -> Order {
        create_order(pool, self.side, self.energy_amount, self.price, self.user_id)
    }
}

// Usage in tests
let order = OrderBuilder::new()
    .with_side("sell")
    .with_amount(500.0)
    .build(&pool);
```

### Test Data Factories

```typescript
// gridtokenx-anchor/tests/utils/factories.ts

export function createTestUser(overrides: Partial<User> = {}): User {
  return {
    publicKey: new anchor.web3.PublicKey("11111111111111111111111111111111"),
    email: `test_${Date.now()}@example.com`,
    balance: new anchor.BN(1000000000),
    ...overrides,
  };
}

export function createTestOrder(overrides: Partial<Order> = {}): Order {
  return {
    side: "buy",
    energyAmount: new anchor.BN(100000000),
    pricePerKwh: new anchor.BN(15000000),
    status: "pending",
    ...overrides,
  };
}
```

## Troubleshooting

### Tests failing randomly
- Check for race conditions
- Ensure test isolation
- Use unique test data per test
- Increase timeouts if needed

### Database connection errors
```bash
# Ensure test database exists
docker exec gridtokenx-postgres psql -U gridtokenx_user -d gridtokenx -c "CREATE DATABASE gridtokenx_test"

# Check connection
echo $TEST_DATABASE_URL
```

### Anchor tests failing
```bash
# Rebuild programs
cd gridtokenx-anchor
anchor clean
anchor build

# Reset validator
solana-test-validator --reset
```

## Related resources

- [Testing Workflow](../workflows/testing.md)
- [Debugging Workflow](../workflows/debugging.md)
- [Anchor Development](../workflows/anchor-development.md)
- [API Development](../workflows/api-development.md)
