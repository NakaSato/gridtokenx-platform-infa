---
description: Database migration management with SQLx
---

# Database Migrations

Manage PostgreSQL database schema using SQLx migrations.

## Quick Commands

// turbo

```bash
# Run all pending migrations
just migrate

# Create new migration
just migrate-new add_users_table

# View migration status
just migrate-info

# Revert last migration
just migrate-revert
```

## Migration Commands

### Run Migrations

```bash
cd gridtokenx-api

# Run all pending migrations
sqlx migrate run

# Run with specific database URL
sqlx migrate run --database-url postgresql://user:pass@localhost:5434/db
```

### Create New Migration

```bash
cd gridtokenx-api

# Create new migration with timestamp
sqlx migrate add <migration_name>

# Example: Create users table
sqlx migrate add create_users_table
```

This creates a new file:
```
gridtokenx-api/migrations/<timestamp>_create_users_table.sql
```

### View Migration Status

```bash
cd gridtokenx-api

# Check applied migrations
sqlx migrate info
```

Output:
```
Applied migrations:
  20240101000000 create_users_table
  20240102000000 create_orders_table

Pending migrations:
  20240103000000 create_markets_table
```

### Revert Migrations

```bash
cd gridtokenx-api

# Revert last migration
sqlx migrate revert

# Revert specific number of migrations
sqlx migrate revert -n 2
```

## Writing Migrations

### Migration Structure

Each migration file has two sections:

```sql
-- Migration: create_users_table
-- Up: Create users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);

-- Down: Revert migration
DROP TABLE IF EXISTS users CASCADE;
```

### Best Practices

1. **Always include DOWN migration**
   ```sql
   -- Down: Must be able to revert
   DROP TABLE IF EXISTS my_table CASCADE;
   ```

2. **Use transactions**
   ```sql
   BEGIN;
   
   CREATE TABLE ...;
   CREATE INDEX ...;
   
   COMMIT;
   ```

3. **Make migrations idempotent**
   ```sql
   CREATE TABLE IF NOT EXISTS ...
   ```

4. **Add indexes for foreign keys**
   ```sql
   CREATE INDEX idx_orders_user_id ON orders(user_id);
   ```

## Common Migrations

### Create Table

```sql
-- Up
CREATE TABLE IF NOT EXISTS trading_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    side VARCHAR(10) NOT NULL,
    energy_amount DECIMAL(18,9) NOT NULL,
    price_per_kwh DECIMAL(18,9) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Down
DROP TABLE IF EXISTS trading_orders CASCADE;
```

### Add Column

```sql
-- Up
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS phone_number VARCHAR(20);

-- Down
ALTER TABLE users 
DROP COLUMN IF EXISTS phone_number;
```

### Create Index

```sql
-- Up
CREATE INDEX IF NOT EXISTS idx_orders_status 
ON trading_orders(status);

-- Down
DROP INDEX IF EXISTS idx_orders_status;
```

### Add Foreign Key

```sql
-- Up
ALTER TABLE order_matches
ADD CONSTRAINT fk_order_id 
FOREIGN KEY (order_id) 
REFERENCES trading_orders(id);

-- Down
ALTER TABLE order_matches
DROP CONSTRAINT IF EXISTS fk_order_id;
```

## Database Operations

### Create Database

```bash
cd gridtokenx-api

# Create database
sqlx database create

# Drop database
sqlx database drop

# Reset database (drop + create)
sqlx database reset
```

### Prepare Offline Queries

For compilation without database connection:

```bash
cd gridtokenx-api

# Prepare queries for offline compilation
cargo sqlx prepare
```

This creates `.sqlx/query-*.json` files for compile-time verification.

## Troubleshooting

### Migration Fails

```bash
# Check current status
sqlx migrate info

# Check database connection
docker exec gridtokenx-postgres \
  psql -U gridtokenx_user -d gridtokenx -c "SELECT 1"

# Re-run failed migration
sqlx migrate run --ignore-missing
```

### Migration Conflict

```bash
# Check migration history
docker exec gridtokenx-postgres psql \
  -U gridtokenx_user -d gridtokenx \
  -c "SELECT * FROM _sqlx_migrations ORDER BY installed_on DESC"
```

### Reset Database

⚠️ **Warning**: Deletes all data!

```bash
# Drop and recreate
sqlx database reset
sqlx migrate run

# Or with Docker
docker-compose down -v
docker-compose up -d postgres
sqlx database create
sqlx migrate run
```

## Related Workflows

- [Database Management](./db-manage.md) - Database operations
- [Docker Services](./docker-services.md) - Manage PostgreSQL
- [Debugging](./debugging.md) - Troubleshoot database issues
