'use client';

import { useState, useEffect } from 'react';

interface RevenueChartProps {
    data?: { date: string; revenue: number }[];
}

export default function RevenueChart({ data }: RevenueChartProps) {
    // Mock data if none provided
    const chartData = data || [
        { date: 'Mon', revenue: 12500 },
        { date: 'Tue', revenue: 18300 },
        { date: 'Wed', revenue: 15700 },
        { date: 'Thu', revenue: 22100 },
        { date: 'Fri', revenue: 19800 },
        { date: 'Sat', revenue: 25600 },
        { date: 'Sun', revenue: 21400 },
    ];

    const maxRevenue = Math.max(...chartData.map((d) => d.revenue));
    const minRevenue = Math.min(...chartData.map((d) => d.revenue));

    return (
        <div className="card">
            <div className="flex items-center justify-between mb-6">
                <div>
                    <h3 className="text-lg font-semibold">Revenue Overview</h3>
                    <p className="text-sm text-[var(--muted)]">Weekly platform earnings</p>
                </div>
                <select className="bg-[var(--card-hover)] border border-[var(--border)] rounded-lg px-3 py-2 text-sm">
                    <option>This Week</option>
                    <option>Last Week</option>
                    <option>This Month</option>
                </select>
            </div>

            {/* Chart */}
            <div className="h-64 flex items-end gap-4">
                {chartData.map((item, index) => {
                    const height = ((item.revenue - minRevenue) / (maxRevenue - minRevenue)) * 100 + 20;
                    return (
                        <div key={index} className="flex-1 flex flex-col items-center gap-2">
                            <div className="relative w-full group">
                                <div
                                    className="w-full bg-gradient-to-t from-[var(--primary)] to-[var(--accent)] rounded-t-lg transition-all duration-300 hover:opacity-80"
                                    style={{ height: `${height}%`, minHeight: '20px' }}
                                />
                                {/* Tooltip */}
                                <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-2 py-1 bg-[var(--card)] border border-[var(--border)] rounded text-xs opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
                                    ฿{item.revenue.toLocaleString()}
                                </div>
                            </div>
                            <span className="text-xs text-[var(--muted)]">{item.date}</span>
                        </div>
                    );
                })}
            </div>

            {/* Summary */}
            <div className="grid grid-cols-3 gap-4 mt-6 pt-6 border-t border-[var(--border)]">
                <div>
                    <p className="text-sm text-[var(--muted)]">Total Revenue</p>
                    <p className="text-xl font-bold">฿{chartData.reduce((acc, d) => acc + d.revenue, 0).toLocaleString()}</p>
                </div>
                <div>
                    <p className="text-sm text-[var(--muted)]">Avg Daily</p>
                    <p className="text-xl font-bold">฿{Math.round(chartData.reduce((acc, d) => acc + d.revenue, 0) / chartData.length).toLocaleString()}</p>
                </div>
                <div>
                    <p className="text-sm text-[var(--muted)]">Peak Day</p>
                    <p className="text-xl font-bold">฿{maxRevenue.toLocaleString()}</p>
                </div>
            </div>
        </div>
    );
}
