---
description: Register admin user and manage authentication
---

# Admin Registration

Register an admin user and manage authentication tokens.

## Quick Command

// turbo

```bash
./scripts/app.sh register
```

## Manual Registration

### 1. Start API Gateway

Ensure the API Gateway is running:

```bash
./scripts/app.sh start
```

Wait for health check:
```bash
curl http://localhost:4000/health
```

### 2. Register Admin User

```bash
curl -X POST http://localhost:4000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "P@ssw0rd123!",
    "username": "admin",
    "first_name": "Admin",
    "last_name": "User"
  }'
```

### 3. Save Access Token

The response will contain an access token:

```json
{
  "data": {
    "auth": {
      "access_token": "eyJhbGciOiJIUzI1NiIs...",
      "refresh_token": "..."
    }
  }
}
```

Save the token:
```bash
echo "eyJhbGciOiJIUzI1NiIs..." > .admin_token
```

## Using the Admin Token

### API Requests

```bash
TOKEN=$(cat .admin_token)

# Authenticated request
curl -X GET http://localhost:4000/api/v1/admin/users \
  -H "Authorization: Bearer $TOKEN"
```

### Admin Operations

```bash
# List all users
curl -X GET http://localhost:4000/api/v1/admin/users \
  -H "Authorization: Bearer $TOKEN"

# Get user details
curl -X GET http://localhost:4000/api/v1/admin/users/{user_id} \
  -H "Authorization: Bearer $TOKEN"

# Create market
curl -X POST http://localhost:4000/api/v1/admin/markets \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Default Market",
    "base_token": "energy",
    "quote_token": "usdc"
  }'
```

## Token Management

### Refresh Token

```bash
curl -X POST http://localhost:4000/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "your-refresh-token"
  }'
```

### Logout

```bash
curl -X POST http://localhost:4000/api/v1/auth/logout \
  -H "Authorization: Bearer $TOKEN"
```

## Database Seeding

Seed database with test users:

```bash
./scripts/app.sh seed
```

Or manually:
```bash
docker exec -i gridtokenx-postgres psql \
  -U gridtokenx_user -d gridtokenx \
  < scripts/seed_1000_users.sql
```

## Admin Roles

| Role | Permissions |
|------|-------------|
| Super Admin | All permissions |
| Admin | User management, market config |
| Operator | Trading operations |
| Viewer | Read-only access |

## Troubleshooting

### Registration Fails

```bash
# Check API Gateway is running
curl http://localhost:4000/health

# Check database connection
docker exec gridtokenx-postgres \
  psql -U gridtokenx_user -d gridtokenx -c "SELECT 1"
```

### Token Expired

```bash
# Re-register or refresh token
./scripts/app.sh register

# Or use refresh endpoint
curl -X POST http://localhost:4000/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token": "..."}'
```

### Permission Denied

Ensure you're using the correct token:
```bash
# Verify token
TOKEN=$(cat .admin_token)
curl -X GET http://localhost:4000/api/v1/auth/me \
  -H "Authorization: Bearer $TOKEN"
```

## Security Notes

- Change default passwords in production
- Use secure JWT secrets
- Enable HTTPS in production
- Rotate tokens periodically
- Store tokens securely (not in plain text)

## Related Workflows

- [Blockchain Initialization](./blockchain-init.md) - Setup blockchain
- [Database Management](./db-manage.md) - Manage users in database
- [Start Development](./start-dev.md) - Start API Gateway
