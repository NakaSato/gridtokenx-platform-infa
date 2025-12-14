# GridTokenX - Simplified User Flow

## User Flow (No Auth Required)

### 1. Landing Page
**URL**: http://localhost:3000
- Auto-redirects to dashboard

### 2. Dashboard
**URL**: http://localhost:3000/dashboard
**Actions**:
1. Click "Connect Wallet"
2. Select Phantom wallet
3. Approve connection
4. View token balance
5. Click "Start Trading" or "Register Meter"

### 3. Register Smart Meter (Optional)
**URL**: http://localhost:3000/meter
**Actions**:
1. Wallet must be connected
2. Enter meter details
3. Submit registration

### 4. Trading
**URL**: http://localhost:3000/p2p
**Actions**:
1. View order book
2. Create offers
3. Trade energy tokens

## Simplified Flow:
```
Landing → Dashboard → Connect Wallet → Trade
```

**No signup or login required!** Just connect your wallet and start trading.
