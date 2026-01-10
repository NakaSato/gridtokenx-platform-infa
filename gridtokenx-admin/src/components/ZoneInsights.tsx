'use client';

import React from 'react';

export interface ZoneTradeStats {
    total_volume_kwh: number;
    intra_zone_volume_kwh: number;
    inter_zone_volume_kwh: number;
    avg_price_per_kwh: number;
}

export interface ZoneRevenueBreakdown {
    zone_id: number;
    total_transaction_value: number;
    total_platform_fees: number;
    total_wheeling_charges: number;
    total_loss_costs: number;
}

export interface ZoneEconomicInsights {
    trade_stats: ZoneTradeStats;
    revenue_breakdown: ZoneRevenueBreakdown[];
    timeframe: string;
}

interface ZoneInsightsProps {
    insights: ZoneEconomicInsights | null;
    loading?: boolean;
}

export default function ZoneInsights({ insights, loading }: ZoneInsightsProps) {
    if (loading) {
        return (
            <div className="card space-y-4 animate-fadeIn">
                <div className="h-6 w-48 bg-secondary rounded animate-pulse" />
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {[1, 2].map((i) => (
                        <div key={i} className="h-32 bg-secondary rounded animate-pulse" />
                    ))}
                </div>
            </div>
        );
    }

    if (!insights) return null;

    const { trade_stats, revenue_breakdown } = insights;
    const selfSufficiency = trade_stats.total_volume_kwh > 0
        ? (trade_stats.intra_zone_volume_kwh / trade_stats.total_volume_kwh) * 100
        : 0;

    return (
        <div className="space-y-6 animate-fadeIn">
            <div className="card">
                <div className="flex items-center justify-between mb-6">
                    <div>
                        <h3 className="text-lg font-semibold">Regional Economic Performance</h3>
                        <p className="text-sm text-muted-foreground">Zone-based trade and revenue distributions</p>
                    </div>
                    <span className="text-xs font-medium px-2 py-1 bg-secondary rounded text-muted-foreground uppercase tracking-wider">
                        Timeframe: {insights.timeframe}
                    </span>
                </div>

                {/* Trade Volume Distribution */}
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-8">
                    <div className="lg:col-span-2 space-y-4">
                        <div className="flex items-center justify-between text-sm">
                            <span className="font-medium">Network Trade Balance</span>
                            <span className={`font-semibold ${selfSufficiency > 70 ? 'text-success' : 'text-warning'}`}>
                                {selfSufficiency.toFixed(1)}% Self-Sufficient
                            </span>
                        </div>
                        <div className="h-4 w-full bg-secondary rounded-full overflow-hidden flex">
                            <div
                                className="h-full bg-linear-to-r from-success to-[#10b981] transition-all duration-500"
                                style={{ width: `${selfSufficiency}%` }}
                                title={`Intra-zone: ${trade_stats.intra_zone_volume_kwh.toLocaleString()} kWh`}
                            />
                            <div
                                className="h-full bg-linear-to-r from-[#3b82f6] to-[#6366f1] transition-all duration-500"
                                style={{ width: `${100 - selfSufficiency}%` }}
                                title={`Inter-zone: ${trade_stats.inter_zone_volume_kwh.toLocaleString()} kWh`}
                            />
                        </div>
                        <div className="flex flex-wrap items-center gap-6 text-xs text-muted-foreground">
                            <div className="flex items-center gap-2">
                                <div className="w-2 h-2 rounded-full bg-success" />
                                <span>Intra-zone: {trade_stats.intra_zone_volume_kwh.toLocaleString()} kWh</span>
                            </div>
                            <div className="flex items-center gap-2">
                                <div className="w-2 h-2 rounded-full bg-[#3b82f6]" />
                                <span>Inter-zone: {trade_stats.inter_zone_volume_kwh.toLocaleString()} kWh</span>
                            </div>
                        </div>
                    </div>

                    <div className="p-4 rounded-xl bg-secondary/30 border border-border flex flex-col justify-center">
                        <p className="text-xs text-muted-foreground mb-1 uppercase tracking-tight font-medium">Total Network Volume</p>
                        <p className="text-2xl font-bold">{trade_stats.total_volume_kwh.toLocaleString()} kWh</p>
                        <div className="mt-2 pt-2 border-t border-border">
                            <span className="text-xs text-muted-foreground">Avg. Price Level: </span>
                            <span className="text-sm font-semibold text-foreground">฿{trade_stats.avg_price_per_kwh.toFixed(2)} / kWh</span>
                        </div>
                    </div>
                </div>

                {/* Per-Zone Financials */}
                <div className="overflow-x-auto">
                    <table className="table">
                        <thead>
                            <tr>
                                <th>Zone ID</th>
                                <th>Transaction Value</th>
                                <th>Platform Fees</th>
                                <th>Wheeling Charges</th>
                                <th>Grid Loss Costs</th>
                                <th>Total Platform Revenue</th>
                            </tr>
                        </thead>
                        <tbody>
                            {revenue_breakdown.map((zone) => {
                                const totalZoneRevenue = zone.total_platform_fees + zone.total_wheeling_charges + zone.total_loss_costs;
                                return (
                                    <tr key={zone.zone_id} className="group">
                                        <td className="font-bold text-foreground">Zone {zone.zone_id}</td>
                                        <td className="font-mono text-sm">฿{zone.total_transaction_value.toLocaleString(undefined, { minimumFractionDigits: 2 })}</td>
                                        <td className="text-success font-medium">฿{zone.total_platform_fees.toLocaleString(undefined, { minimumFractionDigits: 2 })}</td>
                                        <td className="text-[#3b82f6] font-medium">฿{zone.total_wheeling_charges.toLocaleString(undefined, { minimumFractionDigits: 2 })}</td>
                                        <td className="text-warning font-medium">฿{zone.total_loss_costs.toLocaleString(undefined, { minimumFractionDigits: 2 })}</td>
                                        <td className="font-bold text-foreground">฿{totalZoneRevenue.toLocaleString(undefined, { minimumFractionDigits: 2 })}</td>
                                    </tr>
                                );
                            })}
                            {revenue_breakdown.length === 0 && (
                                <tr>
                                    <td colSpan={6} className="text-center py-8 text-muted-foreground italic">
                                        No regional data available for this period
                                    </td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
}
