'use client';

import { useState, useEffect } from 'react';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';

interface Order {
    id: string;
    user_id: string;
    side: 'buy' | 'sell';
    energy_amount: number;
    filled_amount: number;
    price_per_kwh: number;
    status: string;
    created_at: string;
}

export default function OrdersPage() {
    const [orders, setOrders] = useState<Order[]>([]);
    const [loading, setLoading] = useState(true);
    const [statusFilter, setStatusFilter] = useState('all');
    const [sideFilter, setSideFilter] = useState('all');

    useEffect(() => {
        fetchOrders();
    }, [statusFilter, sideFilter]);

    const fetchOrders = async () => {
        setLoading(true);
        const apiBase = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

        try {
            const params = new URLSearchParams();
            if (statusFilter !== 'all') params.append('status', statusFilter);
            if (sideFilter !== 'all') params.append('side', sideFilter);

            const res = await fetch(`${apiBase}/api/v1/trading/orders?${params}`);
            if (res.ok) {
                const data = await res.json();
                setOrders(data.data || data || []);
            }
        } catch (error) {
            console.error('Failed to fetch orders:', error);
            // Mock data for demo
            setOrders([
                { id: 'ORD-001', user_id: 'user_a1b2c3', side: 'buy', energy_amount: 150, filled_amount: 100, price_per_kwh: 4.50, status: 'partially_filled', created_at: '2026-01-06T07:00:00Z' },
                { id: 'ORD-002', user_id: 'user_d4e5f6', side: 'sell', energy_amount: 200, filled_amount: 0, price_per_kwh: 4.45, status: 'pending', created_at: '2026-01-06T06:30:00Z' },
                { id: 'ORD-003', user_id: 'user_g7h8i9', side: 'buy', energy_amount: 100, filled_amount: 100, price_per_kwh: 4.55, status: 'filled', created_at: '2026-01-06T06:00:00Z' },
                { id: 'ORD-004', user_id: 'user_j0k1l2', side: 'sell', energy_amount: 300, filled_amount: 0, price_per_kwh: 4.40, status: 'cancelled', created_at: '2026-01-06T05:30:00Z' },
                { id: 'ORD-005', user_id: 'user_m3n4o5', side: 'buy', energy_amount: 50, filled_amount: 25, price_per_kwh: 4.52, status: 'partially_filled', created_at: '2026-01-06T05:00:00Z' },
            ]);
        } finally {
            setLoading(false);
        }
    };

    const statusColors: Record<string, string> = {
        pending: 'bg-yellow-500/20 text-yellow-400',
        partially_filled: 'bg-blue-500/20 text-blue-400',
        filled: 'bg-green-500/20 text-green-400',
        cancelled: 'bg-red-500/20 text-red-400',
        failed: 'bg-red-500/20 text-red-400',
    };

    const sideColors: Record<string, string> = {
        buy: 'bg-green-500/20 text-green-400',
        sell: 'bg-red-500/20 text-red-400',
    };

    const formatDate = (dateStr: string) => {
        return new Date(dateStr).toLocaleString();
    };

    const calcFillPercent = (filled: number, total: number) => {
        return Math.round((filled / total) * 100);
    };

    return (
        <div className="space-y-6 animate-fadeIn">
            {/* Page Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold">Orders Management</h1>
                    <p className="text-[var(--muted)]">View and manage all P2P trading orders</p>
                </div>
                <button onClick={fetchOrders} className="btn-primary flex items-center gap-2">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                    </svg>
                    Refresh
                </button>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                {[
                    { label: 'Total Orders', value: orders.length, color: 'primary' },
                    { label: 'Pending', value: orders.filter(o => o.status === 'pending').length, color: 'warning' },
                    { label: 'Filled', value: orders.filter(o => o.status === 'filled').length, color: 'success' },
                    { label: 'Cancelled', value: orders.filter(o => o.status === 'cancelled').length, color: 'danger' },
                ].map((stat, i) => (
                    <div key={i} className="card flex items-center gap-4">
                        <div className={`w-12 h-12 rounded-xl bg-[var(--${stat.color})]/20 flex items-center justify-center text-[var(--${stat.color})]`}>
                            <span className="text-xl font-bold">{stat.value}</span>
                        </div>
                        <p className="text-[var(--muted)]">{stat.label}</p>
                    </div>
                ))}
            </div>

            {/* Filters */}
            <div className="card">
                <div className="flex flex-col md:flex-row gap-4">
                    <select
                        value={statusFilter}
                        onChange={(e) => setStatusFilter(e.target.value)}
                        className="bg-[var(--card-hover)] border border-[var(--border)] rounded-lg px-4 py-2"
                    >
                        <option value="all">All Status</option>
                        <option value="pending">Pending</option>
                        <option value="partially_filled">Partially Filled</option>
                        <option value="filled">Filled</option>
                        <option value="cancelled">Cancelled</option>
                    </select>
                    <select
                        value={sideFilter}
                        onChange={(e) => setSideFilter(e.target.value)}
                        className="bg-[var(--card-hover)] border border-[var(--border)] rounded-lg px-4 py-2"
                    >
                        <option value="all">All Sides</option>
                        <option value="buy">Buy Orders</option>
                        <option value="sell">Sell Orders</option>
                    </select>
                </div>
            </div>

            {/* Orders Table */}
            <div className="card">
                {loading ? (
                    <div className="space-y-4">
                        {[1, 2, 3, 4, 5].map((i) => (
                            <div key={i} className="flex items-center gap-4">
                                <Skeleton className="h-10 w-24" />
                                <Skeleton className="h-10 w-20" />
                                <Skeleton className="h-10 flex-1" />
                                <Skeleton className="h-10 w-32" />
                            </div>
                        ))}
                    </div>
                ) : (
                    <div className="overflow-x-auto">
                        <table className="table">
                            <thead>
                                <tr>
                                    <th>Order ID</th>
                                    <th>User</th>
                                    <th>Side</th>
                                    <th>Amount (kWh)</th>
                                    <th>Filled</th>
                                    <th>Price/kWh</th>
                                    <th>Status</th>
                                    <th>Created</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {orders.map((order) => (
                                    <tr key={order.id}>
                                        <td className="font-mono text-sm">{order.id}</td>
                                        <td className="font-mono text-sm text-[var(--muted)]">{order.user_id}</td>
                                        <td>
                                            <Badge className={sideColors[order.side]}>
                                                {order.side.toUpperCase()}
                                            </Badge>
                                        </td>
                                        <td className="font-medium">{order.energy_amount}</td>
                                        <td>
                                            <div className="flex items-center gap-2">
                                                <div className="w-16 h-2 bg-[var(--card-hover)] rounded-full overflow-hidden">
                                                    <div
                                                        className="h-full bg-[var(--primary)] rounded-full"
                                                        style={{ width: `${calcFillPercent(order.filled_amount, order.energy_amount)}%` }}
                                                    />
                                                </div>
                                                <span className="text-sm text-[var(--muted)]">
                                                    {calcFillPercent(order.filled_amount, order.energy_amount)}%
                                                </span>
                                            </div>
                                        </td>
                                        <td className="font-medium">฿{order.price_per_kwh.toFixed(2)}</td>
                                        <td>
                                            <Badge className={statusColors[order.status]}>
                                                {order.status.replace('_', ' ')}
                                            </Badge>
                                        </td>
                                        <td className="text-[var(--muted)] text-sm">{formatDate(order.created_at)}</td>
                                        <td>
                                            <button className="p-2 rounded-lg hover:bg-[var(--card-hover)] transition-colors" title="View Details">
                                                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                                </svg>
                                            </button>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>
        </div>
    );
}
