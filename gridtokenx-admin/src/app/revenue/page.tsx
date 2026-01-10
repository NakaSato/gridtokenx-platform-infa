'use client';

import { useState, useEffect } from 'react';
import { StatCard, ZoneInsights } from '@/components';
import { ZoneEconomicInsights } from '@/components/ZoneInsights';

interface RevenueRecord {
    id: string;
    settlement_id: string;
    amount: number;
    revenue_type: string;
    description: string;
    created_at: string;
}

interface RevenueSummary {
    total_fees: number;
    total_wheeling: number;
    total_loss_cost: number;
    grand_total: number;
}

export default function RevenuePage() {
    const [summary, setSummary] = useState<RevenueSummary>({
        total_fees: 0,
        total_wheeling: 0,
        total_loss_cost: 0,
        grand_total: 0,
    });
    const [records, setRecords] = useState<RevenueRecord[]>([]);
    const [zoneInsights, setZoneInsights] = useState<ZoneEconomicInsights | null>(null);
    const [loading, setLoading] = useState(true);
    const [dateRange, setDateRange] = useState('month'); // Changed default to month
    const [adminToken, setAdminToken] = useState<string>('');

    useEffect(() => {
        const savedToken = localStorage.getItem('admin_token');
        if (savedToken) setAdminToken(savedToken);
    }, []);

    useEffect(() => {
        if (adminToken || dateRange) {
            fetchRevenueData();
        }
    }, [dateRange, adminToken]);

    const fetchRevenueData = async () => {
        if (!adminToken) {
            console.warn("No admin token found, some data might be missing");
        }
        setLoading(true);
        try {
            // Fetch from API
            const apiBase = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';

            const headers: HeadersInit = {
                'Content-Type': 'application/json',
            };
            if (adminToken) {
                headers['Authorization'] = `Bearer ${adminToken}`;
            }

            // Map timeframe to backend expected format
            const timeframe = dateRange === 'today' ? '24h' : (dateRange === 'week' ? '7d' : '30d');

            const [summaryRes, recordsRes, zoneRes] = await Promise.all([
                fetch(`${apiBase}/api/v1/trading/revenue/summary`, { headers }),
                fetch(`${apiBase}/api/v1/trading/revenue/records?limit=20`, { headers }),
                fetch(`${apiBase}/api/v1/analytics/admin/zones/economic?timeframe=${timeframe}`, { headers }).catch(() => null),
            ]);

            if (summaryRes?.ok) {
                const summaryData = await summaryRes.json();
                setSummary(summaryData.data || summaryData);
            }

            if (recordsRes?.ok) {
                const recordsData = await recordsRes.json();
                setRecords(recordsData.data || recordsData || []);
            }

            if (zoneRes?.ok) {
                const zoneData = await zoneRes.json();
                setZoneInsights(zoneData);
            } else {
                setZoneInsights(null);
            }
        } catch (error) {
            console.error('Failed to fetch revenue data:', error);
            // Use mock data for demo
            setSummary({
                total_fees: 125000,
                total_wheeling: 45000,
                total_loss_cost: 15000,
                grand_total: 185000,
            });
            setRecords([
                { id: '1', settlement_id: 'SET-001', amount: 250, revenue_type: 'platform_fee', description: 'Settlement fee', created_at: new Date().toISOString() },
                { id: '2', settlement_id: 'SET-001', amount: 100, revenue_type: 'wheeling_charge', description: 'Zone 1 to Zone 3', created_at: new Date().toISOString() },
                { id: '3', settlement_id: 'SET-002', amount: 180, revenue_type: 'platform_fee', description: 'Settlement fee', created_at: new Date().toISOString() },
                { id: '4', settlement_id: 'SET-003', amount: 320, revenue_type: 'platform_fee', description: 'Settlement fee', created_at: new Date().toISOString() },
                { id: '5', settlement_id: 'SET-003', amount: 75, revenue_type: 'loss_cost', description: 'Grid loss compensation', created_at: new Date().toISOString() },
            ]);
        } finally {
            setLoading(false);
        }
    };

    const typeColors: Record<string, string> = {
        platform_fee: 'badge-success',
        wheeling_charge: 'badge-info',
        loss_cost: 'badge-warning',
    };

    const typeLabels: Record<string, string> = {
        platform_fee: 'Platform Fee',
        wheeling_charge: 'Wheeling Charge',
        loss_cost: 'Grid Loss',
    };

    return (
        <div className="space-y-6 animate-fadeIn">
            {/* Page Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold">Revenue Dashboard</h1>
                    <p className="text-muted">Track platform earnings and fee breakdown</p>
                </div>
                <div className="flex items-center gap-4">
                    <select
                        value={dateRange}
                        onChange={(e) => setDateRange(e.target.value)}
                        className="bg-card border border-border rounded-lg px-4 py-2"
                    >
                        <option value="today">Today</option>
                        <option value="week">This Week</option>
                        <option value="month">This Month</option>
                        <option value="year">This Year</option>
                    </select>
                    <button className="btn-primary flex items-center gap-2">
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                        </svg>
                        Export CSV
                    </button>
                </div>
            </div>

            {/* Revenue Stats */}
            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
                <StatCard
                    title="Total Revenue"
                    value={`฿${summary.grand_total.toLocaleString()}`}
                    change="+8.3% from last period"
                    changeType="positive"
                    subtitle="All revenue sources"
                    icon={
                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                    }
                />
                <StatCard
                    title="Platform Fees"
                    value={`฿${summary.total_fees.toLocaleString()}`}
                    subtitle="1% per settlement"
                    icon={
                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
                        </svg>
                    }
                />
                <StatCard
                    title="Wheeling Charges"
                    value={`฿${summary.total_wheeling.toLocaleString()}`}
                    subtitle="Cross-zone transfers"
                    icon={
                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
                        </svg>
                    }
                />
                <StatCard
                    title="Grid Loss Costs"
                    value={`฿${summary.total_loss_cost.toLocaleString()}`}
                    subtitle="Transmission losses"
                    icon={
                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                        </svg>
                    }
                />
            </div>

            {/* Revenue Breakdown Chart */}
            <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
                <div className="xl:col-span-2 card">
                    <h3 className="text-lg font-semibold mb-6">Revenue Breakdown</h3>
                    <div className="flex items-center gap-8">
                        {/* Pie Chart Visual */}
                        <div className="relative w-48 h-48">
                            <svg viewBox="0 0 100 100" className="w-full h-full transform -rotate-90">
                                <circle
                                    cx="50"
                                    cy="50"
                                    r="40"
                                    fill="none"
                                    stroke="var(--success)"
                                    strokeWidth="20"
                                    strokeDasharray={`${(summary.total_fees / summary.grand_total) * 251.2} 251.2`}
                                />
                                <circle
                                    cx="50"
                                    cy="50"
                                    r="40"
                                    fill="none"
                                    stroke="var(--accent)"
                                    strokeWidth="20"
                                    strokeDasharray={`${(summary.total_wheeling / summary.grand_total) * 251.2} 251.2`}
                                    strokeDashoffset={`${-(summary.total_fees / summary.grand_total) * 251.2}`}
                                />
                                <circle
                                    cx="50"
                                    cy="50"
                                    r="40"
                                    fill="none"
                                    stroke="var(--warning)"
                                    strokeWidth="20"
                                    strokeDasharray={`${(summary.total_loss_cost / summary.grand_total) * 251.2} 251.2`}
                                    strokeDashoffset={`${-((summary.total_fees + summary.total_wheeling) / summary.grand_total) * 251.2}`}
                                />
                            </svg>
                            <div className="absolute inset-0 flex flex-col items-center justify-center">
                                <span className="text-2xl font-bold">100%</span>
                                <span className="text-xs text-muted">Total</span>
                            </div>
                        </div>

                        {/* Legend */}
                        <div className="space-y-4">
                            <div className="flex items-center gap-3">
                                <div className="w-4 h-4 rounded bg-(--success)"></div>
                                <div>
                                    <p className="font-medium">Platform Fees</p>
                                    <p className="text-sm text-muted">{((summary.total_fees / summary.grand_total) * 100).toFixed(1)}% (฿{summary.total_fees.toLocaleString()})</p>
                                </div>
                            </div>
                            <div className="flex items-center gap-3">
                                <div className="w-4 h-4 rounded bg-accent"></div>
                                <div>
                                    <p className="font-medium">Wheeling Charges</p>
                                    <p className="text-sm text-muted">{((summary.total_wheeling / summary.grand_total) * 100).toFixed(1)}% (฿{summary.total_wheeling.toLocaleString()})</p>
                                </div>
                            </div>
                            <div className="flex items-center gap-3">
                                <div className="w-4 h-4 rounded bg-(--warning)"></div>
                                <div>
                                    <p className="font-medium">Grid Loss Costs</p>
                                    <p className="text-sm text-muted">{((summary.total_loss_cost / summary.grand_total) * 100).toFixed(1)}% (฿{summary.total_loss_cost.toLocaleString()})</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Quick Stats */}
                <div className="card">
                    <h3 className="text-lg font-semibold mb-4">Revenue Insights</h3>
                    <div className="space-y-4">
                        <div className="p-4 rounded-lg bg-linear-to-r from-(--success)/10 to-transparent border-l-4 border-(--success)">
                            <p className="text-sm text-muted">Avg. Fee per Settlement</p>
                            <p className="text-xl font-bold">฿245.50</p>
                        </div>
                        <div className="p-4 rounded-lg bg-linear-to-r from-(--accent)/10 to-transparent border-l-4 border-accent">
                            <p className="text-sm text-muted">Cross-Zone Rate</p>
                            <p className="text-xl font-bold">32%</p>
                        </div>
                        <div className="p-4 rounded-lg bg-linear-to-r from-(--warning)/10 to-transparent border-l-4 border-(--warning)">
                            <p className="text-sm text-muted">Avg. Loss Factor</p>
                            <p className="text-xl font-bold">2.8%</p>
                        </div>
                    </div>
                </div>
            </div>

            {/* Zone Insights Section */}
            <ZoneInsights insights={zoneInsights} loading={loading} />

            {/* Revenue Records Table */}
            <div className="card">
                <div className="flex items-center justify-between mb-6">
                    <div>
                        <h3 className="text-lg font-semibold">Recent Revenue Entries</h3>
                        <p className="text-sm text-muted">Detailed transaction log</p>
                    </div>
                    <button className="btn-secondary text-sm">View All Records</button>
                </div>

                {loading ? (
                    <div className="flex items-center justify-center py-12">
                        <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
                    </div>
                ) : (
                    <div className="overflow-x-auto">
                        <table className="table">
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>Settlement</th>
                                    <th>Type</th>
                                    <th>Amount</th>
                                    <th>Description</th>
                                    <th>Date</th>
                                </tr>
                            </thead>
                            <tbody>
                                {records.map((record) => (
                                    <tr key={record.id}>
                                        <td className="font-mono text-sm">{record.id}</td>
                                        <td className="font-mono text-sm text-muted">{record.settlement_id}</td>
                                        <td>
                                            <span className={`badge ${typeColors[record.revenue_type] || 'badge-info'}`}>
                                                {typeLabels[record.revenue_type] || record.revenue_type}
                                            </span>
                                        </td>
                                        <td className="font-semibold text-success">+฿{record.amount.toLocaleString()}</td>
                                        <td className="text-muted">{record.description}</td>
                                        <td className="text-muted">
                                            {new Date(record.created_at).toLocaleDateString()}
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
