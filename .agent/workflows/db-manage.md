---
description: Database management commands
---
# Database Management

Commands for managing the PostgreSQL database.

## Prerequisites
- Docker running
- Database container up

## Start Database
```bash
cd /Users/chanthawat/Developments/gridtokenx-platform-infa && docker-compose up -d postgres
```

## Connect to Database
```bash
docker exec -it gridtokenx-postgres psql -U gridtokenx_user -d gridtokenx
```

## Reset Database
Warning: This will delete all data!

```bash
# Stop services first
docker-compose down -v

# Restart with fresh database
docker-compose up -d postgres

# Run migrations
cd /Users/chanthawat/Developments/gridtokenx-platform-infa/gridtokenx-apigateway
sqlx database create
sqlx migrate run
```

## View Tables
```sql
\dt
```

## Common Queries
```sql
-- List users
SELECT id, email, username, created_at FROM users;

-- List orders
SELECT id, user_id, side, energy_amount, price_per_kwh, status FROM trading_orders;

-- List trades
SELECT * FROM order_matches;
```
