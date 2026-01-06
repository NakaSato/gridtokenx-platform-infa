# GridTokenX Admin Portal

A modern admin dashboard for managing the GridTokenX energy trading platform.

## Features

- **Dashboard**: Overview of platform stats, revenue, and recent activity
- **Revenue**: Detailed revenue tracking with breakdowns by type
- **Users**: User management with search and filtering
- **Orders**: View and manage trading orders
- **Settlements**: Track settlement status and history
- **Certificates**: Manage Renewable Energy Certificates (RECs)
- **Meters**: View registered smart meters

## Getting Started

### Prerequisites

- Node.js 18+
- bun

### Installation

```bash
cd gridtokenx-admin
bun install
```

### Development

```bash
bun run dev
```

The admin portal will be available at [http://localhost:3000](http://localhost:3000).

### Environment Variables

Create a `.env.local` file:

```env
NEXT_PUBLIC_API_URL=http://localhost:3001
```

## Tech Stack

- **Framework**: Next.js 15 with App Router
- **Styling**: Tailwind CSS
- **Language**: TypeScript
- **State**: React Hooks

## Project Structure

```
src/
├── app/
│   ├── page.tsx          # Dashboard
│   ├── revenue/          # Revenue management
│   ├── users/            # User management
│   ├── orders/           # Order management
│   ├── settlements/      # Settlement tracking
│   ├── certificates/     # REC management
│   ├── meters/           # Meter management
│   └── settings/         # Admin settings
├── components/
│   ├── Sidebar.tsx       # Navigation sidebar
│   ├── Header.tsx        # Top header bar
│   ├── StatCard.tsx      # Statistics card
│   └── RevenueChart.tsx  # Revenue visualization
└── styles/
    └── globals.css       # Global styles
```

## API Integration

The admin portal connects to the GridTokenX API Gateway for data:

- `GET /api/v1/trading/revenue/summary` - Revenue summary
- `GET /api/v1/trading/revenue/records` - Detailed revenue records
- `GET /api/admin/users` - User list (requires admin auth)
- `GET /api/trading/orders` - Order list

## License

MIT
