'use client'

import React from 'react'
import {
    useAdminStats,
    useZoneEconomicInsights,
    useAuth
} from '@/hooks/useApi'
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from '@/components/ui/card'
import {
    BarChart3,
    TrendingUp,
    Users,
    Activity,
    Map,
    Box,
    ArrowUpRight,
    TrendingDown,
    Loader2
} from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import {
    BarChart,
    Bar,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip as RechartsTooltip,
    ResponsiveContainer,
    PieChart,
    Pie,
    Cell
} from 'recharts'

export function AdminAnalytics() {
    const { token } = useAuth()
    const { stats, loading: statsLoading } = useAdminStats(token ?? undefined)
    const { insights, loading: insightsLoading } = useZoneEconomicInsights('24h', token ?? undefined)

    if ((statsLoading || insightsLoading) && (!stats || !insights)) {
        return (
            <div className="flex h-96 items-center justify-center">
                <Loader2 className="h-12 w-12 animate-spin text-primary" />
                <span className="ml-4 text-xl font-medium">Synthesizing Platform Intelligence...</span>
            </div>
        )
    }

    const chartData = insights?.revenue_breakdown.map(zone => ({
        name: `Zone ${zone.zone_id}`,
        fees: zone.total_platform_fees,
        wheeling: zone.total_wheeling_charges
    })) || []

    const tradeDistribution = [
        { name: 'Intra-Zone', value: insights?.trade_stats.intra_zone_percent ?? 50 },
        { name: 'Inter-Zone', value: insights?.trade_stats.inter_zone_percent ?? 50 },
    ]

    const COLORS = ['#3b82f6', '#8b5cf6']

    return (
        <div className="space-y-6">
            {/* Global Highlights */}
            <div className="grid gap-4 md:grid-cols-4">
                <MetricCard
                    title="Global Users"
                    value={stats?.total_users.toString() ?? '0'}
                    icon={<Users className="h-5 w-5" />}
                    trend="+12%"
                />
                <MetricCard
                    title="Active Meters"
                    value={`${stats?.active_meters}/${stats?.total_meters}`}
                    icon={<Activity className="h-5 w-5" />}
                    description="Verification rate: 98%"
                />
                <MetricCard
                    title="Total Volume"
                    value={`${stats?.total_volume_kwh.toFixed(1)} kWh`}
                    icon={<Box className="h-5 w-5" />}
                    trend="+5.4%"
                />
                <MetricCard
                    title="Settlement Success"
                    value={`${stats?.settlement_success_rate}%`}
                    icon={<TrendingUp className="h-5 w-5 text-green-500" />}
                    description="Zero failure threshold"
                />
            </div>

            <div className="grid gap-6 md:grid-cols-3">
                {/* Zone Revenue Chart */}
                <Card className="md:col-span-2 border-none shadow-lg bg-card/60 backdrop-blur-sm">
                    <CardHeader>
                        <CardTitle className="text-xl font-bold flex items-center gap-2">
                            <TrendingUp className="h-5 w-5 text-primary" />
                            Zone Revenue Breakdown
                        </CardTitle>
                        <CardDescription>Platform fees and wheeling charges across grid sectors.</CardDescription>
                    </CardHeader>
                    <CardContent className="h-80">
                        {chartData.length === 0 ? (
                            <div className="h-full flex items-center justify-center text-muted-foreground">
                                No revenue data available yet
                            </div>
                        ) : (
                            <ResponsiveContainer width="100%" height="100%">
                                <BarChart data={chartData}>
                                    <CartesianGrid strokeDasharray="3 3" opacity={0.1} />
                                    <XAxis dataKey="name" />
                                    <YAxis />
                                    <RechartsTooltip
                                        contentStyle={{ backgroundColor: 'rgba(23, 23, 23, 0.8)', borderColor: '#333', borderRadius: '8px' }}
                                    />
                                    <Bar dataKey="fees" fill="#3b82f6" radius={[4, 4, 0, 0]} name="Platform Fees" />
                                    <Bar dataKey="wheeling" fill="#8b5cf6" radius={[4, 4, 0, 0]} name="Wheeling Charges" />
                                </BarChart>
                            </ResponsiveContainer>
                        )}
                    </CardContent>
                </Card>

                {/* Trade Distribution */}
                <Card className="border-none shadow-lg bg-card/60 backdrop-blur-sm">
                    <CardHeader>
                        <CardTitle className="text-xl font-bold flex items-center gap-2">
                            <Map className="h-5 w-5 text-primary" />
                            Trade Scope
                        </CardTitle>
                    </CardHeader>
                    <CardContent className="flex flex-col items-center">
                        <div className="h-48 w-full">
                            <ResponsiveContainer width="100%" height="100%">
                                <PieChart>
                                    <Pie
                                        data={tradeDistribution}
                                        innerRadius={60}
                                        outerRadius={80}
                                        paddingAngle={5}
                                        dataKey="value"
                                    >
                                        {tradeDistribution.map((entry, index) => (
                                            <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                        ))}
                                    </Pie>
                                    <RechartsTooltip />
                                </PieChart>
                            </ResponsiveContainer>
                        </div>
                        <div className="w-full space-y-3 mt-4">
                            {tradeDistribution.map((entry, index) => (
                                <div key={entry.name} className="flex justify-between items-center text-sm">
                                    <div className="flex items-center gap-2">
                                        <div className="h-3 w-3 rounded-full" style={{ backgroundColor: COLORS[index] }}></div>
                                        <span className="text-muted-foreground">{entry.name}</span>
                                    </div>
                                    <span className="font-bold">{entry.value.toFixed(1)}%</span>
                                </div>
                            ))}
                        </div>
                    </CardContent>
                </Card>
            </div>
        </div>
    )
}

function MetricCard({ title, value, icon, trend, description }: any) {
    return (
        <Card className="bg-card/40 backdrop-blur-md border border-white/5 hover:border-primary/20 transition-all group">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground group-hover:text-primary transition-colors">{title}</CardTitle>
                <div className="p-2 bg-muted rounded-lg group-hover:bg-primary/10 transition-colors">
                    {icon}
                </div>
            </CardHeader>
            <CardContent>
                <div className="text-2xl font-bold flex items-end gap-2">
                    {value}
                    {trend && (
                        <span className="text-xs text-green-500 flex items-center mb-1">
                            <ArrowUpRight className="h-3 w-3" />
                            {trend}
                        </span>
                    )}
                </div>
                {description && (
                    <p className="text-[10px] text-muted-foreground mt-1 opacity-70">
                        {description}
                    </p>
                )}
            </CardContent>
        </Card>
    )
}
