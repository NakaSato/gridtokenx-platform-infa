# GridTokenX HTTP REST API Reference

> **Version:** 1.0.0  
> **Base URL:** `http://localhost:8080/api/v1`  
> **OpenAPI Spec:** `/api/docs` (Swagger UI)

This document provides a comprehensive reference for the GridTokenX HTTP REST API, designed for frontend integration.

---

## Table of Contents

1. [Authentication](#authentication)
2. [API Endpoints](#api-endpoints)
   - [Authentication](#authentication-endpoints)
   - [Users](#users-endpoints)
   - [Meters](#meters-endpoints)
   - [Trading](#trading-endpoints)
   - [Analytics](#analytics-endpoints)
   - [Wallets](#wallets-endpoints)
   - [Notifications](#notifications-endpoints)
   - [Dashboard](#dashboard-endpoints)
   - [Status & Health](#status--health-endpoints)
3. [Data Types](#data-types)
4. [Error Handling](#error-handling)
5. [WebSocket API](#websocket-api)

---

## Authentication

The API uses JWT Bearer token authentication. Include the token in the `Authorization` header:

```
Authorization: Bearer <access_token>
```

### Token Lifecycle
- **Access Token Expiry:** 24 hours (configurable)
- **Refresh:** Not implemented (re-login required after expiry)

---

## API Endpoints

### Authentication Endpoints

#### Login
```
POST /api/v1/auth/token
```

**Request Body:**
```json
{
  "username": "string",  // Username or email
  "password": "string"
}
```

**Response:** [`AuthResponse`](#authresponse)
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "expires_in": 86400,
  "user": {
    "id": "uuid",
    "username": "johndoe",
    "email": "john@example.com",
    "role": "prosumer",
    "first_name": "John",
    "last_name": "Doe",
    "wallet_address": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
    "balance": "1000.50",
    "locked_amount": "50.00",
    "locked_energy": "100.00"
  }
}
```

---

#### Verify Email
```
GET /api/v1/auth/verify?token={verification_token}
```

**Query Parameters:**
| Parameter | Type   | Required | Description |
|-----------|--------|----------|-------------|
| `token`   | string | Yes      | Email verification token |

**Response:** [`VerifyEmailResponse`](#verifyemailresponse)
```json
{
  "success": true,
  "message": "Email verified successfully",
  "wallet_address": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
  "auth": {
    "access_token": "...",
    "expires_in": 86400,
    "user": {}
  }
}
```

---

#### Forgot Password
```
POST /api/v1/auth/forgot-password
```

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Response:**
```json
{
  "message": "Password reset email sent"
}
```

---

#### Reset Password
```
POST /api/v1/auth/reset-password
```

**Request Body:**
```json
{
  "token": "reset_token_from_email",
  "new_password": "NewSecurePassword123!"
}
```

**Response:**
```json
{
  "message": "Password reset successfully"
}
```

---

#### Change Password (Authenticated)
```
POST /api/v1/auth/change-password
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "current_password": "CurrentPassword123!",
  "new_password": "NewSecurePassword456!"
}
```

**Response:**
```json
{
  "message": "Password changed successfully"
}
```

---

### Users Endpoints

#### Register User
```
POST /api/v1/users
```

**Request Body:**
```json
{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "SecurePassword123!",
  "first_name": "John",
  "last_name": "Doe"
}
```

**Response:** [`RegistrationResponse`](#registrationresponse)
```json
{
  "message": "Registration successful. Please verify your email.",
  "email_verification_sent": true,
  "auth": null
}
```

---

#### Get Current User Profile
```
GET /api/v1/users/me
```

**Headers:** `Authorization: Bearer <token>`

**Response:** [`UserResponse`](#userresponse)
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "username": "johndoe",
  "email": "john@example.com",
  "role": "prosumer",
  "first_name": "John",
  "last_name": "Doe",
  "wallet_address": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
  "balance": "1000.50",
  "locked_amount": "50.00",
  "locked_energy": "100.00"
}
```

---

#### Get My Meters
```
GET /api/v1/users/me/meters
```

**Headers:** `Authorization: Bearer <token>`

**Response:** Array of [`MeterResponse`](#meterresponse)
```json
[
  {
    "id": "uuid",
    "serial_number": "MTR-001",
    "meter_type": "Solar_Prosumer",
    "location": "Bangkok, Thailand",
    "is_verified": true,
    "wallet_address": "7xKX...",
    "latitude": 13.7563,
    "longitude": 100.5018,
    "zone_id": 1
  }
]
```

---

#### Update Wallet Address
```
POST /api/v1/users/wallet
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "wallet_address": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
  "verify_ownership": true
}
```

**Response:**
```json
{
  "message": "Wallet address updated",
  "wallet_address": "7xKX..."
}
```

---

#### Generate Wallet
```
POST /api/v1/users/wallet/generate
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "wallet_address": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
  "secret_key": "[1, 2, 3, ...]",  // Array of bytes (store securely!)
  "message": "Wallet generated. Store your secret key securely."
}
```

---

### Meters Endpoints

#### Register Meter
```
POST /api/v1/meters
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "serial_number": "MTR-001",
  "meter_type": "Solar_Prosumer",
  "location": "123 Main St, Bangkok",
  "latitude": 13.7563,
  "longitude": 100.5018,
  "zone_id": 1
}
```

**Response:** [`RegisterMeterResponse`](#registermeterresponse)
```json
{
  "id": "uuid",
  "serial_number": "MTR-001",
  "message": "Meter registered successfully"
}
```

---

#### List Meters (Filtered)
```
GET /api/v1/meters?status={status}&zone_id={zone_id}
```

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
| Parameter | Type   | Required | Description |
|-----------|--------|----------|-------------|
| `status`  | string | No       | Filter by status: `pending`, `verified`, `rejected` |
| `zone_id` | int    | No       | Filter by zone ID |

**Response:** Array of [`MeterResponse`](#meterresponse)

---

#### Get Meter Statistics
```
GET /api/v1/meters/stats
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "total_meters": 10,
  "verified_meters": 8,
  "pending_meters": 2,
  "total_energy_generated": 5000.5,
  "total_energy_consumed": 3000.25
}
```

---

#### Update Meter Status
```
PATCH /api/v1/meters/{serial}
```

**Headers:** `Authorization: Bearer <token>`

**Path Parameters:**
| Parameter | Type   | Description |
|-----------|--------|-------------|
| `serial`  | string | Meter serial number |

**Request Body:**
```json
{
  "status": "active"
}
```

---

#### Get Meter Health
```
GET /api/v1/meters/{serial}/health
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "serial_number": "MTR-001",
  "status": "healthy",
  "last_reading_at": "2026-02-20T14:00:00Z",
  "uptime_percentage": 99.5,
  "total_readings": 1000,
  "failed_readings": 5
}
```

---

#### Submit Meter Reading
```
POST /api/v1/meters/{serial}/readings
```

**Headers:** `Authorization: Bearer <token>`

**Path Parameters:**
| Parameter | Type   | Description |
|-----------|--------|-------------|
| `serial`  | string | Meter serial number |

**Request Body:**
```json
{
  "reading_value": 1234.56,
  "reading_type": "generation",
  "timestamp": "2026-02-20T14:00:00Z"
}
```

**Response:** [`CreateReadingResponse`](#createreadingresponse)
```json
{
  "id": "uuid",
  "meter_id": "uuid",
  "reading_value": 1234.56,
  "reading_type": "generation",
  "timestamp": "2026-02-20T14:00:00Z",
  "minted": false
}
```

---

#### Get Meter Readings
```
GET /api/v1/meters/{serial}/readings?start={start}&end={end}
```

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
| Parameter | Type   | Required | Description |
|-----------|--------|----------|-------------|
| `start`   | string | No       | Start date (ISO 8601) |
| `end`     | string | No       | End date (ISO 8601) |
| `page`    | int    | No       | Page number (default: 1) |
| `limit`   | int    | No       | Items per page (default: 20, max: 100) |

---

#### Get Meter Trends
```
GET /api/v1/meters/{serial}/trends?period={period}
```

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
| Parameter | Type   | Description |
|-----------|--------|-------------|
| `period`  | string | Period: `day`, `week`, `month`, `year` |

**Response:**
```json
{
  "meter_id": "uuid",
  "period": "week",
  "trends": [
    {
      "date": "2026-02-20",
      "total_generation": 150.5,
      "total_consumption": 100.25,
      "net_energy": 50.25
    }
  ]
}
```

---

#### Mint Tokens from Reading
```
POST /api/v1/meters/readings/{reading_id}/mint
```

**Headers:** `Authorization: Bearer <token>`

**Path Parameters:**
| Parameter   | Type   | Description |
|-------------|--------|-------------|
| `reading_id`| string | Reading UUID |

**Response:**
```json
{
  "success": true,
  "message": "Tokens minted successfully",
  "amount": "50.25",
  "transaction_signature": "5xKJ..."
}
```

---

#### Get Zones
```
GET /api/v1/meters/zones
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
[
  {
    "zone_id": 1,
    "name": "Central Bangkok",
    "description": "Downtown Bangkok area",
    "meter_count": 50
  }
]
```

---

#### Get Zone Statistics
```
GET /api/v1/meters/zones/{zone_id}/stats
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "zone_id": 1,
  "total_meters": 50,
  "active_meters": 45,
  "total_generation": 10000.5,
  "total_consumption": 8000.25,
  "net_energy": 2000.25
}
```

---

### Trading Endpoints

#### Create Order
```
POST /api/v1/trading/orders
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "side": "buy",
  "order_type": "limit",
  "energy_amount": 100.5,
  "price_per_kwh": 2.50
}
```

**Response:** [`CreateOrderResponse`](#createorderresponse)
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "open",
  "created_at": "2026-02-20T14:00:00Z",
  "message": "Order created successfully"
}
```

---

#### Get My Orders
```
GET /api/v1/trading/orders?status={status}&side={side}
```

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
| Parameter    | Type   | Description |
|--------------|--------|-------------|
| `status`     | string | Filter by: `open`, `filled`, `cancelled`, `partial` |
| `side`       | string | Filter by: `buy`, `sell` |
| `order_type` | string | Filter by: `limit`, `market` |
| `page`       | int    | Page number (default: 1) |
| `page_size`  | int    | Items per page (default: 20, max: 100) |
| `sort_by`    | string | Sort by: `created_at`, `price_per_kwh`, `energy_amount` |
| `sort_order` | string | `asc` or `desc` (default: `desc`) |

**Response:** [`TradingOrdersResponse`](#tradingordersresponse)
```json
{
  "data": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "side": "buy",
      "order_type": "limit",
      "energy_amount": 100.5,
      "price_per_kwh": 2.50,
      "filled_amount": 50.0,
      "status": "partial",
      "created_at": "2026-02-20T14:00:00Z",
      "updated_at": "2026-02-20T14:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total_items": 45,
    "total_pages": 3
  }
}
```

---

#### Cancel Order
```
DELETE /api/v1/trading/orders/{id}
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "message": "Order cancelled successfully",
  "id": "uuid"
}
```

---

#### Update Order
```
PUT /api/v1/trading/orders/{id}
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "price_per_kwh": 3.00,
  "energy_amount": 150.0
}
```

---

#### Get Order Book
```
GET /api/v1/trading/orderbook?depth={depth}
```

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `depth`   | int  | Number of price levels (default: 10) |

**Response:** [`OrderBookResponse`](#orderbookresponse)
```json
{
  "bids": [
    { "price": 2.50, "quantity": 100.0, "order_count": 5 },
    { "price": 2.45, "quantity": 200.0, "order_count": 8 }
  ],
  "asks": [
    { "price": 2.55, "quantity": 150.0, "order_count": 3 },
    { "price": 2.60, "quantity": 180.0, "order_count": 6 }
  ],
  "last_updated": "2026-02-20T14:00:00Z"
}
```

---

#### Get My Trades
```
GET /api/v1/trading/trades
```

**Headers:** `Authorization: Bearer <token>`

**Response:** [`TradeHistoryResponse`](#tradehistoryresponse)
```json
{
  "trades": [
    {
      "id": "uuid",
      "order_id": "uuid",
      "side": "buy",
      "energy_amount": 50.0,
      "price_per_kwh": 2.50,
      "total_price": 125.0,
      "counterparty": "counterparty_wallet_address",
      "executed_at": "2026-02-20T14:00:00Z"
    }
  ],
  "pagination": {}
}
```

---

#### Get Token Balance
```
GET /api/v1/trading/balance
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "wallet_address": "7xKX...",
  "available_balance": "1000.50",
  "locked_balance": "50.00",
  "total_balance": "1050.50"
}
```

---

#### Get Blockchain Market Data
```
GET /api/v1/trading/market/blockchain
```

**Headers:** `Authorization: Bearer <token>`

**Response:** [`BlockchainMarketData`](#blockchainmarketdata)
```json
{
  "authority": "7xKX...",
  "active_orders": 150,
  "total_volume": 50000,
  "total_trades": 1200,
  "market_fee_bps": 25,
  "clearing_enabled": true,
  "created_at": 1708444800
}
```

---

#### Conditional Orders (Stop-Loss/Take-Profit)
```
POST /api/v1/trading/conditional
GET /api/v1/trading/conditional
DELETE /api/v1/trading/conditional/{id}
```

**Request Body (POST):**
```json
{
  "trigger_price": 2.00,
  "trigger_type": "stop_loss",
  "side": "sell",
  "energy_amount": 100.0
}
```

---

#### Recurring Orders (DCA)
```
POST /api/v1/trading/recurring
GET /api/v1/trading/recurring
GET /api/v1/trading/recurring/{id}
DELETE /api/v1/trading/recurring/{id}
POST /api/v1/trading/recurring/{id}/pause
POST /api/v1/trading/recurring/{id}/resume
```

**Request Body (POST):**
```json
{
  "side": "buy",
  "energy_amount": 50.0,
  "max_price": 3.00,
  "schedule": "daily",
  "start_date": "2026-02-20"
}
```

---

#### Price Alerts
```
POST /api/v1/trading/price-alerts
GET /api/v1/trading/price-alerts
DELETE /api/v1/trading/price-alerts/{id}
```

**Request Body (POST):**
```json
{
  "target_price": 3.50,
  "condition": "above",
  "notification_method": "push"
}
```

---

#### Export Data
```
GET /api/v1/trading/export/csv?start={start}&end={end}
GET /api/v1/trading/export/json?start={start}&end={end}
```

---

#### P2P Cost Calculator
```
POST /api/v1/trading/p2p/calculate-cost
```

**Request Body:**
```json
{
  "energy_amount": 100.0,
  "price_per_kwh": 2.50
}
```

**Response:**
```json
{
  "energy_amount": 100.0,
  "price_per_kwh": 2.50,
  "subtotal": 250.0,
  "platform_fee": 0.625,
  "network_fee": 0.01,
  "total_cost": 250.635
}
```

---

#### Get P2P Market Prices
```
GET /api/v1/trading/p2p/market-prices
```

**Response:**
```json
{
  "current_price": 2.50,
  "high_24h": 2.80,
  "low_24h": 2.20,
  "volume_24h": 5000.0,
  "price_change_24h": 0.05
}
```

---

#### Matching Status
```
GET /api/v1/trading/matching-status
```

**Response:**
```json
{
  "status": "active",
  "last_match_at": "2026-02-20T14:00:00Z",
  "pending_orders": 25,
  "matched_today": 150
}
```

---

#### Settlement Statistics
```
GET /api/v1/trading/settlement-stats
```

**Response:**
```json
{
  "total_settlements": 5000,
  "pending_settlements": 10,
  "total_volume_settled": 150000.0,
  "average_settlement_time_seconds": 30
}
```

---

#### Revenue Summary (Admin)
```
GET /api/v1/trading/revenue/summary
GET /api/v1/trading/revenue/records
```

---

#### Admin Match Orders
```
POST /api/v1/trading/admin/match-orders
```

**Headers:** `Authorization: Bearer <token>` (requires admin role)

---

### Analytics Endpoints

#### Market Analytics
```
GET /api/v1/analytics/market
```

**Headers:** `Authorization: Bearer <token>`

**Response:** [`MarketAnalytics`](#marketanalytics)
```json
{
  "overview": {
    "total_volume_24h": 5000.0,
    "total_trades_24h": 150,
    "current_price": 2.50,
    "price_change_24h": 0.05
  },
  "volume": [
    { "date": "2026-02-20", "buy_volume": 2500.0, "sell_volume": 2500.0 }
  ],
  "price_statistics": {
    "high": 2.80,
    "low": 2.20,
    "average": 2.50,
    "median": 2.48
  }
}
```

---

#### User Trading Stats
```
GET /api/v1/analytics/my-stats
```

**Headers:** `Authorization: Bearer <token>`

**Response:** [`UserTradingStats`](#usertradingstats)
```json
{
  "overall": {
    "total_trades": 50,
    "total_volume": 5000.0,
    "total_spent": 12500.0,
    "total_earned": 10000.0,
    "profit_loss": -2500.0
  },
  "as_buyer": {
    "trades": 30,
    "volume": 3000.0,
    "total_spent": 7500.0
  },
  "as_seller": {
    "trades": 20,
    "volume": 2000.0,
    "total_earned": 10000.0
  }
}
```

---

#### User Wealth History
```
GET /api/v1/analytics/my-history?period={period}
```

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
| Parameter | Type   | Description |
|-----------|--------|-------------|
| `period`  | string | `week`, `month`, `year` |

**Response:**
```json
{
  "period": "month",
  "data": [
    { "date": "2026-02-01", "balance": 1000.0, "energy_held": 500.0 },
    { "date": "2026-02-02", "balance": 1050.0, "energy_held": 480.0 }
  ]
}
```

---

#### User Transactions
```
GET /api/v1/analytics/transactions
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "transactions": [
    {
      "id": "uuid",
      "type": "trade",
      "amount": 250.0,
      "energy_amount": 100.0,
      "timestamp": "2026-02-20T14:00:00Z",
      "description": "Bought 100 kWh at 2.50/kWh"
    }
  ],
  "pagination": {}
}
```

---

#### Admin Analytics
```
GET /api/v1/analytics/admin/stats
GET /api/v1/analytics/admin/activity
GET /api/v1/analytics/admin/health
GET /api/v1/analytics/admin/zones/economic
```

**Headers:** `Authorization: Bearer <token>` (requires admin role)

---

### Wallets Endpoints

#### List User Wallets
```
GET /api/v1/user-wallets
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
[
  {
    "id": "uuid",
    "wallet_address": "7xKX...",
    "is_primary": true,
    "linked_at": "2026-02-20T14:00:00Z"
  }
]
```

---

#### Link Wallet
```
POST /api/v1/user-wallets
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "wallet_address": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU"
}
```

---

#### Remove Wallet
```
DELETE /api/v1/user-wallets/{id}
```

---

#### Set Primary Wallet
```
PUT /api/v1/user-wallets/{id}/primary
```

---

#### Get Wallet Balance (Legacy)
```
GET /api/v1/wallets/{address}/balance
```

**Response:**
```json
{
  "wallet_address": "7xKX...",
  "balance": "1000.50",
  "locked_amount": "50.00"
}
```

---

### Notifications Endpoints

#### List Notifications
```
GET /api/v1/notifications
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "notifications": [
    {
      "id": "uuid",
      "type": "trade_executed",
      "title": "Trade Executed",
      "message": "Your buy order for 100 kWh has been filled",
      "read": false,
      "created_at": "2026-02-20T14:00:00Z"
    }
  ],
  "unread_count": 5
}
```

---

#### Mark as Read
```
PUT /api/v1/notifications/{id}/read
```

---

#### Mark All as Read
```
PUT /api/v1/notifications/read-all
```

---

#### Get/Update Preferences
```
GET /api/v1/notifications/preferences
PUT /api/v1/notifications/preferences
```

**Request Body (PUT):**
```json
{
  "email_enabled": true,
  "push_enabled": true,
  "trade_notifications": true,
  "price_alert_notifications": true,
  "system_notifications": true
}
```

---

### Dashboard Endpoints

#### Get Dashboard Metrics
```
GET /api/v1/dashboard/metrics
```

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "balance": {
    "available": 1000.50,
    "locked": 50.00,
    "energy_held": 500.0
  },
  "today": {
    "energy_generated": 25.5,
    "energy_consumed": 18.0,
    "trades": 3,
    "volume": 150.0
  },
  "month": {
    "energy_generated": 750.0,
    "energy_consumed": 540.0,
    "trades": 45,
    "volume": 4500.0,
    "revenue": 1125.0
  },
  "active_orders": {
    "buy": 2,
    "sell": 1
  }
}
```

---

### Status & Health Endpoints

#### System Status
```
GET /api/v1/status
```

**Response:** [`StatusResponse`](#statusresponse)
```json
{
  "status": "operational",
  "services": {
    "database": "healthy",
    "blockchain": "healthy",
    "cache": "healthy"
  },
  "version": "1.0.0"
}
```

---

#### Meter Status
```
GET /api/v1/status/meters
```

**Response:**
```json
{
  "total": 100,
  "active": 95,
  "inactive": 5,
  "by_zone": [
    { "zone_id": 1, "count": 50 },
    { "zone_id": 2, "count": 45 }
  ]
}
```

---

#### Readiness Probe
```
GET /api/v1/status/ready
```

**Response:**
```json
{
  "ready": true,
  "checks": {
    "database": { "status": "passed", "latency_ms": 5 },
    "blockchain": { "status": "passed", "latency_ms": 100 }
  }
}
```

---

#### Liveness Probe
```
GET /api/v1/status/live
```

**Response:**
```json
{
  "alive": true,
  "uptime_seconds": 86400
}
```

---

#### Health Check (Root)
```
GET /health
GET /api/health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2026-02-20T14:00:00Z",
  "dependencies": {
    "database": "healthy",
    "redis": "healthy",
    "solana": "healthy"
  }
}
```

---

### Public Endpoints (No Auth)

#### Public Meters
```
GET /api/v1/public/meters
```

**Response:** Array of [`PublicMeterResponse`](#publicmeterresponse)
```json
[
  {
    "location": "Bangkok, Thailand",
    "meter_type": "Solar_Prosumer",
    "is_verified": true,
    "latitude": 13.7563,
    "longitude": 100.5018
  }
]
```

---

#### Grid Status
```
GET /api/v1/public/grid-status
GET /api/v1/public/grid-status/history
```

**Response:**
```json
{
  "total_generation": 5000.0,
  "total_consumption": 4500.0,
  "net_flow": 500.0,
  "active_meters": 95
}
```

---

#### Batch Readings (Simulator)
```
POST /api/v1/public/meters/batch/readings
```

---

### Simulator Endpoints

#### Register Meter by ID
```
POST /api/v1/simulator/meters/register
```

**Headers:** `Authorization: Bearer <token>`

---

### Developer Endpoints

#### Faucet (Dev Only)
```
POST /api/v1/dev/faucet
```

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "wallet_address": "7xKX..."
}
```

**Response:**
```json
{
  "signature": "5xKJ...",
  "amount": 1000.0,
  "message": "Tokens airdropped successfully"
}
```

---

#### Metrics
```
GET /metrics
```

**Response:** Prometheus metrics format

---

## Data Types

### AuthResponse
| Field | Type | Description |
|-------|------|-------------|
| `access_token` | string | JWT access token |
| `expires_in` | int | Token expiry in seconds |
| `user` | UserResponse | User details |

### UserResponse
| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | User ID |
| `username` | string | Username |
| `email` | string | Email address |
| `role` | string | User role: `admin`, `prosumer`, `consumer` |
| `first_name` | string | First name |
| `last_name` | string | Last name |
| `wallet_address` | string? | Solana wallet address (optional) |
| `balance` | decimal | Token balance |
| `locked_amount` | decimal | Locked token amount |
| `locked_energy` | decimal | Locked energy amount |

### MeterResponse
| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Meter ID |
| `serial_number` | string | Unique serial number |
| `meter_type` | string | Type: `Solar_Prosumer`, `Consumer_Only`, etc. |
| `location` | string | Physical location |
| `is_verified` | bool | Verification status |
| `wallet_address` | string | Associated wallet |
| `latitude` | float? | Latitude coordinate |
| `longitude` | float? | Longitude coordinate |
| `zone_id` | int? | Zone ID |

### PublicMeterResponse
| Field | Type | Description |
|-------|------|-------------|
| `location` | string | Display location |
| `meter_type` | string | Meter type |
| `is_verified` | bool | Verification status |
| `latitude` | float? | Latitude |
| `longitude` | float? | Longitude |

### TradingOrder
| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Order ID |
| `user_id` | UUID | Owner user ID |
| `side` | OrderSide | `buy` or `sell` |
| `order_type` | OrderType | `limit` or `market` |
| `energy_amount` | decimal | Energy amount (kWh) |
| `price_per_kwh` | decimal | Price per kWh |
| `filled_amount` | decimal | Amount filled |
| `status` | OrderStatus | `open`, `partial`, `filled`, `cancelled` |
| `created_at` | datetime | Creation timestamp |
| `updated_at` | datetime | Last update timestamp |

### OrderBookEntry
| Field | Type | Description |
|-------|------|-------------|
| `price` | decimal | Price level |
| `quantity` | decimal | Total quantity at price |
| `order_count` | int | Number of orders |

---

## Error Handling

All errors follow a consistent format:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ]
  }
}
```

### HTTP Status Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request / Validation Error |
| 401 | Unauthorized (missing or invalid token) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Not Found |
| 409 | Conflict (e.g., duplicate resource) |
| 422 | Unprocessable Entity |
| 429 | Too Many Requests (rate limited) |
| 500 | Internal Server Error |
| 503 | Service Unavailable |

### Common Error Codes

| Code | Description |
|------|-------------|
| `AUTH_INVALID_CREDENTIALS` | Invalid username/password |
| `AUTH_TOKEN_EXPIRED` | JWT token has expired |
| `AUTH_TOKEN_INVALID` | Invalid JWT token |
| `VALIDATION_ERROR` | Request validation failed |
| `RESOURCE_NOT_FOUND` | Requested resource not found |
| `INSUFFICIENT_BALANCE` | Not enough tokens/energy |
| `METER_NOT_VERIFIED` | Meter requires verification |
| `ORDER_NOT_CANCELABLE` | Order cannot be cancelled |

---

## WebSocket API

### Connection
```
ws://localhost:8080/ws
ws://localhost:8080/ws/{channel}
ws://localhost:8080/api/market/ws
```

### Channels

| Channel | Description |
|---------|-------------|
| `/ws` | General WebSocket connection |
| `/ws/trading` | Trading updates |
| `/ws/market` | Market data stream |
| `/ws/notifications` | Real-time notifications |

### Message Format

```json
{
  "type": "trade_executed",
  "channel": "trading",
  "data": {
    "order_id": "uuid",
    "energy_amount": 100.0,
    "price": 2.50
  },
  "timestamp": "2026-02-20T14:00:00Z"
}
```

### Event Types

| Type | Description |
|------|-------------|
| `order_created` | New order placed |
| `order_filled` | Order fully/partially filled |
| `order_cancelled` | Order cancelled |
| `trade_executed` | Trade completed |
| `price_update` | Market price change |
| `balance_update` | Account balance changed |
| `notification` | New notification |

---

## Rate Limiting

| Endpoint Category | Rate Limit |
|-------------------|------------|
| Authentication | 10 req/min |
| Public APIs | 100 req/min |
| Authenticated APIs | 1000 req/min |
| Trading | 100 req/min |

Rate limit headers are included in responses:
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 950
X-RateLimit-Reset: 1708444800
```

---

## CORS Configuration

Allowed origins are configured server-side. Default development settings allow:
- `http://localhost:3000`
- `http://localhost:5173`
- `http://127.0.0.1:3000`

Allowed methods: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS`

Allowed headers: `Authorization`, `Content-Type`, `Accept`

Credentials: Enabled

---

## SDK & Client Libraries

### TypeScript/JavaScript Example

```typescript
const API_BASE = 'http://localhost:8080/api/v1';

async function login(username: string, password: string) {
  const response = await fetch(`${API_BASE}/auth/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password })
  });
  
  if (!response.ok) {
    throw new Error('Login failed');
  }
  
  const data = await response.json();
  localStorage.setItem('access_token', data.access_token);
  return data;
}

async function getProfile() {
  const token = localStorage.getItem('access_token');
  const response = await fetch(`${API_BASE}/users/me`, {
    headers: { 
      'Authorization': `Bearer ${token}` 
    }
  });
  return response.json();
}

async function createOrder(order: {
  side: 'buy' | 'sell';
  order_type: 'limit' | 'market';
  energy_amount: number;
  price_per_kwh: number;
}) {
  const token = localStorage.getItem('access_token');
  const response = await fetch(`${API_BASE}/trading/orders`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(order)
  });
  return response.json();
}
```

---

## Changelog

### v1.0.0 (Current)
- Initial RESTful API release
- Authentication with JWT
- User management
- Meter management and readings
- P2P energy trading
- Analytics and dashboard
- WebSocket real-time updates
- Notification system

---

## Support

- **Documentation:** `/api/docs` (Swagger UI)
- **OpenAPI Spec:** `/api/docs/openapi.json`
- **GitHub Issues:** [Project Repository]
- **Email:** support@gridtokenx.com
