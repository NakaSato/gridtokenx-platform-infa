---
description: Register admin user and manage authentication
---

# Admin Registration

GridTokenX requires an admin user for platform operations like market creation, user KYC approval, and oracle management.

## Quick Registration

The easiest way to register the initial admin is using the application manager:

// turbo

```bash
./scripts/app.sh register
```
This script will prompt for credentials and initialize the admin record in the `iam-service` database.

## Manual Registration (via API)

If you prefer to use `curl`, ensure the **API Gateway (Kong)** is running:

### 1. Register User
```bash
curl -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@gridtokenx.com",
    "password": "SecurePassword123!",
    "username": "admin",
    "first_name": "Platform",
    "last_name": "Admin"
  }'
```

### 2. Obtain JWT Token
Login to get your access token:
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@gridtokenx.com",
    "password": "SecurePassword123!"
  }'
```

The response will contain:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "..."
}
```

## Admin Operations

Once registered, use the token for protected routes:

```bash
TOKEN="your_access_token"

# List all platform users
curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/v1/admin/users

# Create a new Energy Market
curl -X POST http://localhost:8000/api/v1/admin/markets \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Bangkok South", "zone": "TH-BKK-01"}'
```

## Seed Data
For development, you can seed the database with test prosumers and consumers:

// turbo

```bash
./scripts/app.sh seed --users 50
```

## Troubleshooting

- **401 Unauthorized**: Token has expired. Use the refresh token or log in again.
- **Connection Refused**: Ensure Kong is running and mapped to port `8000` (or `4000` for direct API access).
- **Service Unavailable**: Check if `iam-service` is up and connected to PostgreSQL.

## Related Workflows
- [IAM Service](./iam-service-development.md) - Deep dive into identity logic.
- [Database Management](./db-manage.md) - Direct database access.
- [API Development](./api-development.md) - Adding new admin endpoints.
