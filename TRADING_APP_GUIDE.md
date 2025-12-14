# GridTokenX Trading App - User Guide

## Current Demo User

**Wallet**: `2Xyfzwzq7vATKYYT2SPjERVbQESq8F4PXo1WNmo1Ba29`
**Balance**: 212.75 tokens
**Status**: Ready to trade

## Using the Trading App

### 1. Connect Wallet
1. Open http://localhost:3000 in Chrome
2. Click "Connect Wallet" (top right)
3. Select Phantom or other Solana wallet
4. Approve connection

### 2. View Your Balance
- Dashboard shows token balance
- Portfolio tab shows holdings
- Real-time updates via WebSocket

### 3. Create Energy Offer
1. Go to "Trading" tab
2. Click "Create Offer"
3. Enter kWh amount and price
4. Submit offer

### 4. Browse & Trade
- View order book
- Match with buyers/sellers
- Execute trades

## Creating a New User

### Option 1: New Wallet (Quick)
```bash
# Create wallet
solana-keygen new --outfile ~/new_user.json

# Get address
solana-keygen pubkey ~/new_user.json

# Submit meter reading (mint tokens)
curl -X POST http://localhost:4000/api/meters/submit-reading \
  -H "Content-Type: application/json" \
  -d '{"wallet_address":"NEW_WALLET_ADDRESS","kwh_amount":"30","reading_timestamp":"2024-12-14T07:36:00Z"}'
```

### Option 2: Use Trading App
1. Create new Solana wallet in Phantom
2. Copy wallet address
3. Submit meter reading via Gateway
4. Connect wallet in trading app
5. Start trading!

## Demo Flow Summary

✅ **Step 1**: User has wallet
✅ **Step 2**: Submit meter reading → Mint tokens
✅ **Step 3**: View balance in trading app
✅ **Step 4**: Trade with other users

**Platform is fully operational!** 🚀
