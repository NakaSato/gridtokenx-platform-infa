'use client';

import { useState, useEffect } from 'react';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';

interface Settlement {
    id: string;
    match_id: string;
    buyer_id: string;
    seller_id: string;
    energy_amount: number;
    total_value: number;
    fee_amount: number;
    status: string;
    transaction_signature: string | null;
    retry_count: number;
    created_at: string;
}

export default function SettlementsPage() {
    const [settlements, setSettlements] = useState<Settlement[]>([]);
    const [loading, setLoading] = useState(true);
    const [statusFilter, setStatusFilter] = useState('all');

    useEffect(() => {
        fetchSettlements();
    }, [statusFilter]);

    const fetchSettlements = async () => {
        setLoading(true);
        const apiBase = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

        try {
            const params = new URLSearchParams();
            if (statusFilter !== 'all') params.append('status', statusFilter);

            const res = await fetch(`${apiBase}/api/v1/trading/settlements?${params}`);
            if (res.ok) {
                const data = await res.json();
                setSettlements(data.data || data || []);
            }
        } catch (error) {
            console.error('Failed to fetch settlements:', error);
            // Mock data for demo
            setSettlements([
                { id: 'SET-001', match_id: 'MTH-001', buyer_id: 'user_a1b2c3', seller_id: 'user_d4e5f6', energy_amount: 100, total_value: 450, fee_amount: 4.5, status: 'completed', transaction_signature: '5xM2k...7nP9q', retry_count: 0, created_at: '2026-01-06T07:00:00Z' },
                { id: 'SET-002', match_id: 'MTH-002', buyer_id: 'user_g7h8i9', seller_id: 'user_j0k1l2', energy_amount: 50, total_value: 225, fee_amount: 2.25, status: 'pending', transaction_signature: null, retry_count: 0, created_at: '2026-01-06T06:30:00Z' },
                { id: 'SET-003', match_id: 'MTH-003', buyer_id: 'user_m3n4o5', seller_id: 'user_p6q7r8', energy_amount: 200, total_value: 900, fee_amount: 9.0, status: 'failed', transaction_signature: null, retry_count: 2, created_at: '2026-01-06T06:00:00Z' },
                { id: 'SET-004', match_id: 'MTH-004', buyer_id: 'user_s9t0u1', seller_id: 'user_v2w3x4', energy_amount: 75, total_value: 340, fee_amount: 3.4, status: 'completed', transaction_signature: '8kL9m...2nQ3p', retry_count: 0, created_at: '2026-01-06T05:30:00Z' },
                { id: 'SET-005', match_id: 'MTH-005', buyer_id: 'user_y5z6a7', seller_id: 'user_b8c9d0', energy_amount: 150, total_value: 675, fee_amount: 6.75, status: 'processing', transaction_signature: null, retry_count: 1, created_at: '2026-01-06T05:00:00Z' },
            ]);
        } finally {
            setLoading(false);
        }
    };

    const retrySettlement = async (settlementId: string) => {
        const apiBase = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';
        try {
            const res = await fetch(`${apiBase}/api/v1/trading/settlements/${settlementId}/retry`, {
                method: 'POST',
            });
            if (res.ok) {
                fetchSettlements();
            }
        } catch (error) {
            console.error('Failed to retry settlement:', error);
        }
    };

    const statusColors: Record<string, string> = {
        pending: 'bg-yellow-500/20 text-yellow-400',
        processing: 'bg-blue-500/20 text-blue-400',
        completed: 'bg-green-500/20 text-green-400',
        failed: 'bg-red-500/20 text-red-400',
        permanently_failed: 'bg-red-800/20 text-red-500',
    };

    const formatDate = (dateStr: string) => {
        return new Date(dateStr).toLocaleString();
    };

    const totalFees = settlements.reduce((sum, s) => sum + s.fee_amount, 0);
    const totalVolume = settlements.reduce((sum, s) => sum + s.total_value, 0);

    return (
        <div className="space-y-6 animate-fadeIn">
            {/* Page Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold">Settlements</h1>
                    <p className="text-[var(--muted)]">View and manage blockchain settlements</p>
                </div>
                <button onClick={fetchSettlements} className="btn-primary flex items-center gap-2">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                    </svg>
                    Refresh
                </button>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
                {[
                    { label: 'Total', value: settlements.length, icon: '📊' },
                    { label: 'Pending', value: settlements.filter(s => s.status === 'pending').length, icon: '⏳' },
                    { label: 'Completed', value: settlements.filter(s => s.status === 'completed').length, icon: '✅' },
                    { label: 'Failed', value: settlements.filter(s => s.status === 'failed').length, icon: '❌' },
                    { label: 'Fees Collected', value: `฿${totalFees.toFixed(2)}`, icon: '💰' },
                ].map((stat, i) => (
                    <div key={i} className="card flex items-center gap-3">
                        <span className="text-2xl">{stat.icon}</span>
                        <div>
                            <p className="text-sm text-[var(--muted)]">{stat.label}</p>
                            <p className="text-xl font-bold">{stat.value}</p>
                        </div>
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
                        <option value="processing">Processing</option>
                        <option value="completed">Completed</option>
                        <option value="failed">Failed</option>
                    </select>
                    <div className="flex-1" />
                    <div className="text-[var(--muted)]">
                        Total Volume: <span className="font-bold text-white">฿{totalVolume.toLocaleString()}</span>
                    </div>
                </div>
            </div>

            {/* Settlements Table */}
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
                                    <th>Settlement ID</th>
                                    <th>Match</th>
                                    <th>Buyer → Seller</th>
                                    <th>Energy</th>
                                    <th>Value</th>
                                    <th>Fee</th>
                                    <th>Status</th>
                                    <th>TX Signature</th>
                                    <th>Retries</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {settlements.map((settlement) => (
                                    <tr key={settlement.id}>
                                        <td className="font-mono text-sm">{settlement.id}</td>
                                        <td className="font-mono text-sm text-[var(--muted)]">{settlement.match_id}</td>
                                        <td className="text-sm">
                                            <span className="text-[var(--success)]">{settlement.buyer_id.slice(0, 10)}...</span>
                                            <span className="text-[var(--muted)]"> → </span>
                                            <span className="text-[var(--danger)]">{settlement.seller_id.slice(0, 10)}...</span>
                                        </td>
                                        <td className="font-medium">{settlement.energy_amount} kWh</td>
                                        <td className="font-medium">฿{settlement.total_value.toFixed(2)}</td>
                                        <td className="text-[var(--success)]">+฿{settlement.fee_amount.toFixed(2)}</td>
                                        <td>
                                            <Badge className={statusColors[settlement.status]}>
                                                {settlement.status}
                                            </Badge>
                                        </td>
                                        <td className="font-mono text-sm">
                                            {settlement.transaction_signature ? (
                                                <a
                                                    href={`https://explorer.solana.com/tx/${settlement.transaction_signature}?cluster=devnet`}
                                                    target="_blank"
                                                    rel="noopener noreferrer"
                                                    className="text-[var(--primary)] hover:underline"
                                                >
                                                    {settlement.transaction_signature}
                                                </a>
                                            ) : (
                                                <span className="text-[var(--muted)]">-</span>
                                            )}
                                        </td>
                                        <td className={settlement.retry_count > 0 ? 'text-[var(--warning)]' : 'text-[var(--muted)]'}>
                                            {settlement.retry_count}
                                        </td>
                                        <td>
                                            {settlement.status === 'failed' && (
                                                <button
                                                    onClick={() => retrySettlement(settlement.id)}
                                                    className="btn-secondary text-xs flex items-center gap-1"
                                                >
                                                    <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                                                    </svg>
                                                    Retry
                                                </button>
                                            )}
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
