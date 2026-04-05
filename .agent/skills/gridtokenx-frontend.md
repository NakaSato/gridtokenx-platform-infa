---
name: gridtokenx-frontend
description: Frontend development for GridTokenX. Covers Next.js with Bun, trading UI patterns, blockchain integration with Anchor clients, state management, and wallet connections.
user-invocable: true
---

# GridTokenX Frontend Development Skill

## What this Skill is for

Use this Skill when the user asks for:

- **Next.js development** for trading UI, portal, or explorer
- **Bun runtime** configuration and scripts
- **Blockchain integration** with Anchor-generated clients
- **Wallet connection** using Wallet Standard
- **State management** with React Query and Zustand
- **Trading UI components** (order book, charts, positions)
- **API integration** with GridTokenX backend
- **TypeScript** patterns and best practices

## Frontend architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GridTokenX Frontend                       │
├─────────────────────────────────────────────────────────────┤
│  Applications                                                │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐            │
│  │ Trading UI  │ │   Portal    │ │  Explorer   │            │
│  │  (Next.js)  │ │  (Next.js)  │ │  (Next.js)  │            │
│  │  Port 3000  │ │  Port 3001  │ │  Port 3002  │            │
│  └─────────────┘ └─────────────┘ └─────────────┘            │
├─────────────────────────────────────────────────────────────┤
│  Shared Components & Libraries                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  - UI Component Library (shadcn/ui)                 │    │
│  │  - Blockchain Hooks (Anchor clients)                │    │
│  │  - API Client (generated from OpenAPI)              │    │
│  │  - State Management (Zustand stores)                │    │
│  └─────────────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────────┤
│  Integration Layer                                           │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐            │
│  │   Wallet    │ │   Anchor    │ │   REST      │            │
│  │  Standard   │ │   Client    │ │   API       │            │
│  └─────────────┘ └─────────────┘ └─────────────┘            │
└─────────────────────────────────────────────────────────────┘
```

## Project structure

### Trading UI Structure

```
gridtokenx-trading/
├── app/                      # Next.js App Router
│   ├── layout.tsx           # Root layout
│   ├── page.tsx             # Home page
│   ├── dashboard/           # Dashboard pages
│   ├── markets/             # Market pages
│   ├── orders/              # Order management
│   └── settings/            # User settings
├── components/
│   ├── ui/                  # Base UI components
│   ├── trading/             # Trading-specific components
│   ├── wallet/              # Wallet connection
│   └── layout/              # Layout components
├── hooks/                   # Custom React hooks
│   ├── useWallet.ts
│   ├── useMarkets.ts
│   ├── useOrders.ts
│   └── useBlockchain.ts
├── lib/
│   ├── api/                 # API client
│   ├── blockchain/          # Blockchain integration
│   ├── utils/               # Utilities
│   └── constants/           # Constants
├── stores/                  # Zustand stores
│   ├── walletStore.ts
│   ├── orderStore.ts
│   └── marketStore.ts
├── types/                   # TypeScript types
└── public/                  # Static assets
```

## Next.js patterns

### App Router setup

```typescript
// app/layout.tsx
import { Inter } from 'next/font/google';
import { Providers } from './providers';
import { WalletProvider } from '@/components/wallet/WalletProvider';

const inter = Inter({ subsets: ['latin'] });

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <Providers>
          <WalletProvider>
            {children}
          </WalletProvider>
        </Providers>
      </body>
    </html>
  );
}
```

### Server Components with Data Fetching

```typescript
// app/markets/page.tsx
import { api } from '@/lib/api';
import { MarketList } from '@/components/trading/MarketList';

export const dynamic = 'force-dynamic';

export default async function MarketsPage() {
  const markets = await api.getMarkets();
  
  return (
    <div className="container mx-auto p-4">
      <h1 className="text-2xl font-bold mb-4">Markets</h1>
      <MarketList markets={markets} />
    </div>
  );
}
```

### Client Components with Hooks

```typescript
// components/trading/OrderForm.tsx
'use client';

import { useState } from 'react';
import { useWallet } from '@/hooks/useWallet';
import { useCreateOrder } from '@/hooks/useOrders';
import { Button } from '@/components/ui/button';

interface OrderFormProps {
  marketId: string;
}

export function OrderForm({ marketId }: OrderFormProps) {
  const { publicKey } = useWallet();
  const { createOrder, isLoading } = useCreateOrder();
  const [side, setSide] = useState<'buy' | 'sell'>('buy');
  const [amount, setAmount] = useState('');
  const [price, setPrice] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!publicKey) {
      alert('Please connect wallet');
      return;
    }

    await createOrder({
      marketId,
      side,
      energyAmount: parseFloat(amount),
      pricePerKwh: parseFloat(price),
    });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="flex gap-2">
        <Button
          type="button"
          variant={side === 'buy' ? 'default' : 'outline'}
          onClick={() => setSide('buy')}
        >
          Buy
        </Button>
        <Button
          type="button"
          variant={side === 'sell' ? 'default' : 'outline'}
          onClick={() => setSide('sell')}
        >
          Sell
        </Button>
      </div>
      
      <input
        type="number"
        value={amount}
        onChange={(e) => setAmount(e.target.value)}
        placeholder="Amount (kWh)"
        className="w-full p-2 border rounded"
        required
      />
      
      <input
        type="number"
        value={price}
        onChange={(e) => setPrice(e.target.value)}
        placeholder="Price per kWh"
        className="w-full p-2 border rounded"
        required
      />
      
      <Button type="submit" disabled={isLoading} className="w-full">
        {isLoading ? 'Submitting...' : `Place ${side} Order`}
      </Button>
    </form>
  );
}
```

## Blockchain integration

### Wallet Provider Setup

```typescript
// components/wallet/WalletProvider.tsx
'use client';

import { WalletStandardProvider } from '@solana/wallet-standard-react';
import { useMemo } from 'react';

export function WalletProvider({ children }: { children: React.ReactNode }) {
  const wallets = useMemo(() => {
    // Wallet Standard will auto-discover installed wallets
    return [];
  }, []);

  return (
    <WalletStandardProvider wallets={wallets}>
      {children}
    </WalletStandardProvider>
  );
}
```

### Wallet Hook

```typescript
// hooks/useWallet.ts
import { useWallet as useWalletStandard } from '@solana/wallet-standard-react';
import { useConnection } from '@solana/react-hooks';

export function useWallet() {
  const { account, connect, disconnect, signAndSendTransaction } = useWalletStandard();
  const { connection } = useConnection();

  return {
    publicKey: account?.publicKey,
    connected: !!account,
    connect,
    disconnect,
    signAndSendTransaction,
    connection,
  };
}
```

### Anchor Client Integration

```typescript
// lib/blockchain/anchorClient.ts
import { AnchorProvider, Program, Wallet } from '@coral-xyz/anchor';
import { TradingIDL } from '@/types/programs/trading';
import { IDL as TradingIDLJson } from '@/idl/trading.json';

const TRADING_PROGRAM_ID = '69dGpKu9a8EZiZ7orgfTH6CoGj9DeQHHkHBF2exSr8na';

export function getTradingProgram(wallet: Wallet, connection: any): Program<TradingIDL> {
  const provider = new AnchorProvider(connection, wallet, {
    commitment: 'confirmed',
  });

  return new Program<TradingIDL>(
    TradingIDLJson,
    TRADING_PROGRAM_ID,
    provider
  );
}
```

### Trading Hook

```typescript
// hooks/useOrders.ts
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useWallet } from './useWallet';
import { api } from '@/lib/api';
import { BN } from '@coral-xyz/anchor';

interface CreateOrderParams {
  marketId: string;
  side: 'buy' | 'sell';
  energyAmount: number;
  pricePerKwh: number;
}

export function useCreateOrder() {
  const { connection, publicKey } = useWallet();
  const queryClient = useQueryClient();

  const mutation = useMutation({
    mutationFn: async (params: CreateOrderParams) => {
      // Call API
      const response = await api.createOrder(params);
      
      // Or call blockchain directly
      // const program = getTradingProgram(wallet, connection);
      // await program.methods
      //   .createOrder(new BN(params.energyAmount), new BN(params.pricePerKwh))
      //   .accounts({ ... })
      //   .rpc();
      
      return response;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] });
      queryClient.invalidateQueries({ queryKey: ['markets'] });
    },
  });

  return {
    createOrder: mutation.mutateAsync,
    isLoading: mutation.isPending,
    error: mutation.error,
  };
}
```

## State management

### API Client

```typescript
// lib/api/index.ts
import axios from 'axios';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';

export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor for auth
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// API methods
export const apiMethods = {
  // Markets
  getMarkets: () => api.get('/api/v1/markets').then(r => r.data),
  getMarket: (id: string) => api.get(`/api/v1/markets/${id}`).then(r => r.data),
  
  // Orders
  createOrder: (data: any) => api.post('/api/v1/orders', data).then(r => r.data),
  getOrders: () => api.get('/api/v1/orders').then(r => r.data),
  cancelOrder: (id: string) => api.delete(`/api/v1/orders/${id}`).then(r => r.data),
  
  // Users
  getUser: () => api.get('/api/v1/users/me').then(r => r.data),
  getBalance: () => api.get('/api/v1/users/me/balance').then(r => r.data),
};

Object.assign(api, apiMethods);
```

### React Query Setup

```typescript
// app/providers.tsx
'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useState } from 'react';

export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 60 * 1000, // 1 minute
            refetchInterval: 30 * 1000, // 30 seconds for real-time data
          },
        },
      })
  );

  return (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
}
```

### Zustand Store

```typescript
// stores/orderStore.ts
import { create } from 'zustand';
import { Order } from '@/types/order';

interface OrderStore {
  orders: Order[];
  selectedOrder: Order | null;
  setOrders: (orders: Order[]) => void;
  addOrder: (order: Order) => void;
  updateOrder: (id: string, updates: Partial<Order>) => void;
  removeOrder: (id: string) => void;
  setSelectedOrder: (order: Order | null) => void;
}

export const useOrderStore = create<OrderStore>((set) => ({
  orders: [],
  selectedOrder: null,
  
  setOrders: (orders) => set({ orders }),
  
  addOrder: (order) =>
    set((state) => ({
      orders: [...state.orders, order],
    })),
  
  updateOrder: (id, updates) =>
    set((state) => ({
      orders: state.orders.map((order) =>
        order.id === id ? { ...order, ...updates } : order
      ),
    })),
  
  removeOrder: (id) =>
    set((state) => ({
      orders: state.orders.filter((order) => order.id !== id),
    })),
  
  setSelectedOrder: (order) => set({ selectedOrder: order }),
}));
```

## Trading UI components

### Order Book

```typescript
// components/trading/OrderBook.tsx
'use client';

import { useMemo } from 'react';
import { Order } from '@/types/order';

interface OrderBookProps {
  bids: Order[];
  asks: Order[];
  onSelectOrder: (order: Order) => void;
}

export function OrderBook({ bids, asks, onSelectOrder }: OrderBookProps) {
  const maxAmount = useMemo(() => {
    const allOrders = [...bids, ...asks];
    return Math.max(...allOrders.map(o => o.energyAmount), 1);
  }, [bids, asks]);

  return (
    <div className="grid grid-cols-2 gap-4">
      {/* Bids (Buy Orders) */}
      <div className="space-y-1">
        <h3 className="text-green-600 font-semibold">Bids</h3>
        {bids.map((bid) => (
          <OrderBookRow
            key={bid.id}
            order={bid}
            maxAmount={maxAmount}
            type="bid"
            onClick={() => onSelectOrder(bid)}
          />
        ))}
      </div>

      {/* Asks (Sell Orders) */}
      <div className="space-y-1">
        <h3 className="text-red-600 font-semibold">Asks</h3>
        {asks.map((ask) => (
          <OrderBookRow
            key={ask.id}
            order={ask}
            maxAmount={maxAmount}
            type="ask"
            onClick={() => onSelectOrder(ask)}
          />
        ))}
      </div>
    </div>
  );
}

interface OrderBookRowProps {
  order: Order;
  maxAmount: number;
  type: 'bid' | 'ask';
  onClick: () => void;
}

function OrderBookRow({ order, maxAmount, type, onClick }: OrderBookRowProps) {
  const widthPercent = (order.energyAmount / maxAmount) * 100;

  return (
    <div
      className="relative flex justify-between text-sm cursor-pointer hover:bg-gray-100 p-1"
      onClick={onClick}
    >
      {/* Depth bar */}
      <div
        className={`absolute inset-y-0 ${type === 'bid' ? 'bg-green-100' : 'bg-red-100'} opacity-50`}
        style={{ width: `${widthPercent}%`, right: type === 'bid' ? 'auto' : 0, left: type === 'bid' ? 0 : 'auto' }}
      />
      
      <span className={type === 'bid' ? 'text-green-600' : 'text-red-600'}>
        ${order.pricePerKwh.toFixed(4)}
      </span>
      <span>{order.energyAmount.toFixed(2)} kWh</span>
      <span>${(order.energyAmount * order.pricePerKwh).toFixed(2)}</span>
    </div>
  );
}
```

### Price Chart

```typescript
// components/trading/PriceChart.tsx
'use client';

import { Line } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
);

interface PriceChartProps {
  prices: { timestamp: string; price: number }[];
}

export function PriceChart({ prices }: PriceChartProps) {
  const data = {
    labels: prices.map(p => new Date(p.timestamp).toLocaleTimeString()),
    datasets: [
      {
        label: 'Price (USD/kWh)',
        data: prices.map(p => p.price),
        borderColor: 'rgb(59, 130, 246)',
        backgroundColor: 'rgba(59, 130, 246, 0.1)',
        tension: 0.1,
      },
    ],
  };

  const options = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: false,
      },
      tooltip: {
        mode: 'index' as const,
        intersect: false,
      },
    },
    scales: {
      x: {
        display: true,
        title: {
          display: true,
          text: 'Time',
        },
      },
      y: {
        display: true,
        title: {
          display: true,
          text: 'Price (USD)',
        },
      },
    },
  };

  return (
    <div className="h-64 w-full">
      <Line data={data} options={options} />
    </div>
  );
}
```

## Build and deployment

### Bun configuration

```json
// package.json
{
  "name": "gridtokenx-trading",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "test": "bun test"
  },
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.2.0",
    "@tanstack/react-query": "^5.0.0",
    "zustand": "^4.4.0",
    "@coral-xyz/anchor": "^0.29.0",
    "@solana/wallet-standard-react": "^1.0.0"
  }
}
```

### Docker deployment

```dockerfile
# Dockerfile
FROM oven/bun:1 AS base
WORKDIR /app

# Install dependencies
FROM base AS deps
COPY package.json bun.lockb ./
RUN bun install --frozen-lockfile

# Build application
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN bun run build

# Production image
FROM base AS runner
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

CMD ["node", "server.js"]
```

## Testing

### Component tests

```typescript
// components/trading/__tests__/OrderForm.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { OrderForm } from '../OrderForm';

describe('OrderForm', () => {
  it('renders form fields', () => {
    render(<OrderForm marketId="1" />);
    
    expect(screen.getByPlaceholderText('Amount (kWh)')).toBeInTheDocument();
    expect(screen.getByPlaceholderText('Price per kWh')).toBeInTheDocument();
  });

  it('submits order on form submit', async () => {
    const onSubmit = vi.fn();
    render(<OrderForm marketId="1" onSubmit={onSubmit} />);
    
    fireEvent.change(screen.getByPlaceholderText('Amount (kWh)'), {
      target: { value: '100' }
    });
    fireEvent.change(screen.getByPlaceholderText('Price per kWh'), {
      target: { value: '0.15' }
    });
    
    fireEvent.click(screen.getByText('Place Buy Order'));
    
    await waitFor(() => {
      expect(onSubmit).toHaveBeenCalledWith({
        side: 'buy',
        energyAmount: 100,
        pricePerKwh: 0.15,
      });
    });
  });
});
```

### Run tests

```bash
cd gridtokenx-trading

# Run all tests
bun test

# Run specific test file
bun test OrderForm.test.tsx

# Run with coverage
bun test --coverage
```

## Related resources

- [API Development Workflow](../workflows/api-development.md)
- [Testing Workflow](../workflows/testing.md)
- [Anchor Development Workflow](../workflows/anchor-development.md)
- [GridTokenX Dev Skill](./gridtokenx-dev.md)
