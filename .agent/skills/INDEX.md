---
description: Index of all GridTokenX agent skills
---

# GridTokenX Agent Skills

Comprehensive agent skills for developing the GridTokenX P2P energy trading platform.

## Available Skills

### Core Skills

| Skill | Description | When to Use |
|-------|-------------|-------------|
| [gridtokenx-dev](./gridtokenx-dev.md) | Complete platform development guide | General GridTokenX development tasks |
| [gridtokenx-testing](./gridtokenx-testing.md) | Testing strategy and implementation | Writing and running tests |
| [gridtokenx-infra](./gridtokenx-infra.md) | Infrastructure and DevOps | Docker, databases, monitoring |
| [gridtokenx-frontend](./gridtokenx-frontend.md) | Frontend development | Next.js, blockchain integration, UI |

### Solana Development Skills

| Skill | Description | When to Use |
|-------|-------------|-------------|
| [solana-dev](./SKILL.md) | General Solana development | Solana dApp development, wallet integration |
| [programs-anchor](./programs-anchor.md) | Anchor smart contracts | Building Solana programs with Anchor |
| [idl-codegen](./idl-codegen.md) | IDL and client generation | Generating clients from program IDLs |
| [resources](./resources.md) | External resources | Documentation and learning materials |

## Skill Invocation

Skills can be invoked using the `@` symbol in your messages:

```
@gridtokenx-dev How do I create a new trading endpoint?
@gridtokenx-testing Help me write tests for the order service
@gridtokenx-infra Configure Kafka for the smart meter data
@gridtokenx-frontend Create a trading order form component
@solana-dev How to implement PDA validation in Anchor?
```

## Skill Descriptions

### @gridtokenx-dev

**Purpose**: End-to-end GridTokenX platform development

**Covers**:
- P2P energy trading features
- Solana blockchain integration
- Rust backend services (API Gateway, IAM, Trading, Oracle)
- Database operations (PostgreSQL, Redis, InfluxDB)
- Frontend development (Next.js trading UI, portal, explorer)
- IoT integration (smart meters, oracle bridges)
- Infrastructure (Docker, Kafka, monitoring)
- Testing strategies

**Default stack**:
- Backend: Rust with Axum
- Frontend: Next.js with Bun
- Smart Contracts: Anchor
- Database: PostgreSQL + Redis
- Messaging: Kafka
- Infrastructure: Docker Compose

### @gridtokenx-testing

**Purpose**: Comprehensive testing for all GridTokenX components

**Covers**:
- Rust unit and integration tests
- Anchor program tests
- End-to-end trading scenarios
- Load and performance testing
- Test infrastructure setup
- CI/CD integration
- Coverage analysis

**Test categories**:
- Unit tests (fast, isolated)
- Integration tests (service interactions)
- E2E tests (full user journeys)
- Load tests (throughput, stress)

### @gridtokenx-infra

**Purpose**: Infrastructure and DevOps for GridTokenX

**Covers**:
- Docker Compose configuration
- PostgreSQL with replication
- Redis clustering
- Kafka messaging (KRaft mode)
- Monitoring stack (Prometheus, Grafana)
- Service orchestration
- Network configuration
- Production deployment

**Services managed**:
- PostgreSQL (primary + replica)
- Redis (primary + replica)
- InfluxDB (time-series)
- Kafka (event streaming)
- Prometheus (metrics)
- Grafana (dashboards)
- Mailpit (email testing)
- Kong (API gateway)

### @gridtokenx-frontend

**Purpose**: Frontend development for GridTokenX applications

**Covers**:
- Next.js with App Router
- Bun runtime
- Blockchain integration (Anchor clients)
- Wallet connection (Wallet Standard)
- State management (React Query, Zustand)
- Trading UI components
- API integration
- TypeScript patterns

**Applications**:
- Trading UI (port 3000)
- Admin Portal (port 3001)
- Blockchain Explorer (port 3002)
- Smart Meter UI (port 5173)

### @solana-dev

**Purpose**: General Solana dApp development

**Covers**:
- Wallet Standard integration
- @solana/kit usage
- Framework-kit for React/Next.js
- Transaction building and sending
- Program development (Anchor/Pinocchio)
- Testing (LiteSVM, Mollusk, Surfpool)
- Security best practices

**Stack decisions**:
- UI: @solana/client + @solana/react-hooks
- SDK: @solana/kit
- Programs: Anchor (default) or Pinocchio
- Testing: LiteSVM/Mollusk (unit), Surfpool (integration)

### @programs-anchor

**Purpose**: Anchor smart contract development

**Covers**:
- Program structure and macros
- Account types and constraints
- Instruction patterns
- Cross-Program Invocations (CPIs)
- Error handling
- Token accounts (SPL, Token-2022)
- PDAs and account validation
- Security best practices

**Key features**:
- `declare_id!()` - Program address declaration
- `#[program]` - Instruction entrypoints
- `#[derive(Accounts)]` - Account validation
- `#[error_code]` - Custom errors
- `#[event]` - Program events

### @idl-codegen

**Purpose**: IDL generation and client codegen

**Covers**:
- Codama (preferred IDL format)
- Anchor IDL extraction
- Shank IDL for native Rust
- TypeScript client generation
- Rust client generation
- IDL versioning and publishing

**Workflow**:
1. Build program → Generate IDL
2. Convert to Codama format
3. Generate clients with renderers
4. Publish to npm/crates.io

### @resources

**Purpose**: Curated external resources

**Categories**:
- Learning platforms (Blueshift, Solana Cookbook)
- Core documentation (Solana, Anchor, Kit)
- UI and wallet infrastructure
- Testing frameworks (LiteSVM, Mollusk, Surfpool)
- IDL tools (Codama, Shank, Kinobi)
- Security resources

## Workflows Integration

Skills work alongside [workflows](../workflows/README.md):

- **Skills**: Provide expertise and guidance
- **Workflows**: Step-by-step procedures for specific tasks

Example:
```
@gridtokenx-dev How do I add a new trading feature?
→ Provides architecture guidance

Then follow:
- [API Development Workflow](../workflows/api-development.md)
- [Testing Workflow](../workflows/testing.md)
- [Database Migrations Workflow](../workflows/database-migrations.md)
```

## Common Commands by Skill

### @gridtokenx-dev
```bash
./scripts/app.sh start    # Start platform
just test                 # Run tests
just migrate              # Database migrations
```

### @gridtokenx-testing
```bash
cargo test               # Rust tests
anchor test              # Anchor tests
./scripts/run_integration_tests.sh
```

### @gridtokenx-infra
```bash
docker-compose up -d     # Start containers
docker-compose logs -f   # View logs
docker-compose down      # Stop containers
```

### @gridtokenx-frontend
```bash
cd gridtokenx-trading
bun run dev             # Start dev server
bun run build           # Build production
bun test                # Run tests
```

## Best Practices

### When using skills:

1. **Be specific** about what you're trying to accomplish
2. **Mention the layer** you're working on (frontend, backend, blockchain, infra)
3. **Ask for examples** when implementing complex features
4. **Request tests** for new functionality
5. **Consider security** implications for sensitive operations

### Skill collaboration:

Skills can work together:

```
@gridtokenx-dev @gridtokenx-frontend
How do I add a wallet connection to the trading UI?

@gridtokenx-dev @gridtokenx-infra
How do I configure the API Gateway to use Kafka?

@solana-dev @programs-anchor
How do I implement secure PDA validation?
```

## Related Resources

- [Workflows Index](../workflows/README.md) - Step-by-step procedures
- [Project README](../../README.md) - Project overview
- [Solana Documentation](https://solana.com/docs)
- [Anchor Documentation](https://www.anchor-lang.com/)
- [GridTokenX Documentation](../../docs/)

## Contributing

When adding new skills:

1. Create a new `.md` file in this directory
2. Follow the skill template format
3. Include invocation examples
4. Link to related workflows
5. Update this index

## Version Information

- **GridTokenX Platform**: v1.0.0
- **Solana**: 1.17+
- **Anchor**: 0.30+
- **Rust**: 1.75+
- **Node.js/Bun**: Latest
- **PostgreSQL**: 17
- **Docker**: 24+
