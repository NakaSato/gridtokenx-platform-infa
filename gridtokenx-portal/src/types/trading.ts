export interface Bar {
    time: number;
    open: number;
    high: number;
    low: number;
    close: number;
    volume: number;
}

export interface ApiFuturesPosition {
    id: number;
    product_symbol: string;
    side: 'long' | 'short';
    entry_price: string;
    quantity: string;
    unrealized_pnl?: string;
}

export interface ApiOrder {
    id: number;
    order_type?: string;
    side: string;
    price_per_kwh: string;
    energy_amount: string;
    expires_at?: string;
    created_at: string;
}

export interface TradeRecord {
    id: string;
    quantity: string;
    price: string;
    total_value: string;
    role: "buyer" | "seller";
    executed_at: string;
    status: string;
    buy_order_id?: string;
    sell_order_id?: string;
    counterparty_id?: string;
    product_symbol?: string;
    wheeling_charge?: string;
    loss_cost?: string;
    effective_energy?: string;
    buyer_zone_id?: number;
    seller_zone_id?: number;
}

export interface TradeHistory {
    trades: TradeRecord[];
    total_count: number;
}

import { PublicKey } from '@solana/web3.js';
import { BN } from '@coral-xyz/anchor';

export interface OnChainTradeRecord {
    sellOrder: PublicKey;
    buyOrder: PublicKey;
    seller: PublicKey;
    buyer: PublicKey;
    amount: BN;
    pricePerKwh: BN;
    totalValue: BN;
    feeAmount: BN;
    executedAt: BN;
}

export interface PlatformRevenueSummary {
    total_revenue: string;
    platform_fees: string;
    wheeling_charges: string;
    loss_costs: string;
    settlement_count: number;
}

export interface CollectionRecord extends RevenueRecord { }

// --- Admin Analytics & Health ---

export interface AdminStatsResponse {
    total_users: number
    total_meters: number
    active_meters: number
    total_volume_kwh: number
    total_orders: number
    settlement_success_rate: number
}

export interface DependencyHealth {
    name: string
    status: 'healthy' | 'unhealthy' | 'degraded'
    response_time_ms: number | null
    last_check: string
    error_message: string | null
    details: string | null
}

export interface SystemMetrics {
    cpu_usage: number | null
    memory_used_mb: number | null
    memory_total_mb: number | null
    disk_used_gb: number | null
    disk_total_gb: number | null
    active_connections: number
}

export interface DetailedHealthStatus {
    status: 'healthy' | 'unhealthy' | 'degraded'
    timestamp: string
    version: string
    environment: string
    uptime_seconds: number
    dependencies: DependencyHealth[]
    metrics: SystemMetrics
}

export interface AuditEventRecord {
    id: string
    event_type: string
    user_id: string | null
    ip_address: string | null
    event_data: any
    created_at: string
}

export interface AdminUser {
    id: string
    username: string
    email: string
    first_name: string
    last_name: string
    role: string
    wallet_address?: string
    created_at: string
    is_active: boolean
}

export interface AdminUsersResponse {
    users: AdminUser[]
    total: number
}

export interface ZoneRevenueBreakdown {
    zone_id: number
    total_transaction_value: number
    total_platform_fees: number
    total_wheeling_charges: number
    avg_price_per_kwh: number
}

export interface ZoneTradeStats {
    timeframe: string
    total_volume_kwh: number
    intra_zone_volume_kwh: number
    inter_zone_volume_kwh: number
    intra_zone_percent: number
    inter_zone_percent: number
}

export interface ZoneEconomicInsights {
    timeframe: string
    trade_stats: ZoneTradeStats
    revenue_breakdown: ZoneRevenueBreakdown[]
}

export interface RevenueRecord {
    id: string;
    settlement_id: string;
    amount: string;
    revenue_type: string;
    description: string | null;
    created_at: string;
}

// --- Market Stats ---

export interface ZoneStats {
    zone_id: number;
    generator_count: number;
    consumer_count: number;
    total_generation: string;
    total_consumption: string;
    net_balance: string;
}

export interface MarketStatsResponse {
    total_generation: string;
    total_consumption: string;
    net_balance: string;
    active_users: number;
    zones: ZoneStats[];
}