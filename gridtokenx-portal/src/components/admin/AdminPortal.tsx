'use client'

import React from 'react'
import Link from 'next/link'
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from '@/components/ui/card'
import {
    CircleDollarSign,
    Zap,
    Users,
    Activity,
    ArrowRight,
    TrendingUp,
    BarChart3,
    LayoutDashboard,
    Clock,
    Shield,
    Settings,
    Map
} from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { useAdminStats, useAuth } from '@/hooks/useApi'
import { GridTopologyMap } from './GridTopologyMap'

function QuickStat({ label, value, trend, icon: Icon, color }: any) {
    return (
        <Card className="border-none shadow-sm bg-card/40 backdrop-blur-sm">
            <CardContent className="p-4">
                <div className="flex items-center justify-between">
                    <div className="p-2 bg-muted rounded-lg">
                        <Icon className={`h-4 w-4 ${color}`} />
                    </div>
                    {trend && (
                        <span className="text-xs text-green-500 flex items-center">
                            <TrendingUp className="h-3 w-3 mr-0.5" />
                            {trend}
                        </span>
                    )}
                </div>
                <div className="mt-3">
                    <div className="text-2xl font-bold">{value}</div>
                    <div className="text-xs text-muted-foreground">{label}</div>
                </div>
            </CardContent>
        </Card>
    )
}

export function AdminPortal() {
    const { token } = useAuth()
    const { stats, loading } = useAdminStats(token ?? undefined)

    const adminTools = [
        {
            title: 'Revenue & Collection',
            description: 'Monitor platform fees, wheeling charges, and on-chain settlement revenue.',
            href: '/admin/revenue',
            icon: CircleDollarSign,
            badge: 'Financial',
            color: 'text-green-500',
            borderColor: 'border-l-green-500',
            bgColor: 'bg-green-500/10'
        },
        {
            title: 'Grid Operations',
            description: 'Live topology map, transmission congestion monitoring, and branch capacity management.',
            href: '/admin/grid',
            icon: Map,
            badge: 'Live',
            color: 'text-orange-500',
            borderColor: 'border-l-orange-500',
            bgColor: 'bg-orange-500/10'
        },
        {
            title: 'VPP Orchestration',
            description: 'Manage Virtual Power Plant clusters and trigger grid balancing dispatches.',
            href: '/admin/vpp',
            icon: Zap,
            badge: 'Grid Ops',
            color: 'text-yellow-500',
            borderColor: 'border-l-yellow-500',
            bgColor: 'bg-yellow-500/10'
        },
        {
            title: 'User Management',
            description: 'Review user registrations, roles, and linked wallet addresses.',
            href: '/admin/users',
            icon: Users,
            badge: 'Governance',
            color: 'text-blue-500',
            borderColor: 'border-l-blue-500',
            bgColor: 'bg-blue-500/10'
        },
        {
            title: 'System Health',
            description: 'Monitor API gateway performance, database status, and blockchain sync.',
            href: '/admin/health',
            icon: Activity,
            badge: 'DevOps',
            color: 'text-purple-500',
            borderColor: 'border-l-purple-500',
            bgColor: 'bg-purple-500/10'
        },
        {
            title: 'Activity Log',
            description: 'Comprehensive audit trail of security and operational events.',
            href: '/admin/activity',
            icon: LayoutDashboard,
            badge: 'Audit',
            color: 'text-indigo-500',
            borderColor: 'border-l-indigo-500',
            bgColor: 'bg-indigo-500/10'
        },
        {
            title: 'P2P Configuration',
            description: 'Manage wheeling charges, loss factors, and market pricing parameters without smart contract redeployment.',
            href: '/admin/p2p-config',
            icon: Settings,
            badge: 'Market',
            color: 'text-cyan-500',
            borderColor: 'border-l-cyan-500',
            bgColor: 'bg-cyan-500/10'
        }
    ]

    return (
        <div className="space-y-8">
            {/* Welcome Banner */}
            <Card className="bg-gradient-to-r from-primary/10 via-primary/5 to-transparent border-none">
                <CardContent className="p-6 flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
                    <div className="flex items-center gap-4">
                        <div className="p-3 bg-primary/10 rounded-xl">
                            <Shield className="h-6 w-6 text-primary" />
                        </div>
                        <div>
                            <h2 className="text-lg font-semibold">Welcome to Admin Command Center</h2>
                            <p className="text-sm text-muted-foreground">
                                Centralized orchestration and monitoring for the GridTokenX ecosystem.
                            </p>
                        </div>
                    </div>
                    <div className="flex items-center gap-2 text-sm text-muted-foreground">
                        <Clock className="h-4 w-4" />
                        <span>{new Date().toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</span>
                    </div>
                </CardContent>
            </Card>

            {/* Quick Stats */}
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                <QuickStat
                    label="Total Users"
                    value={stats?.total_users ?? (loading ? '...' : '0')}
                    trend="+12%"
                    icon={Users}
                    color="text-blue-500"
                />
                <QuickStat
                    label="Active Meters"
                    value={stats?.active_meters ?? (loading ? '...' : '0')}
                    trend="Active"
                    icon={Zap}
                    color="text-yellow-500"
                />
                <QuickStat
                    label="Total Volume"
                    value={stats ? `${stats.total_volume_kwh.toFixed(1)} kWh` : (loading ? '...' : '0 kWh')}
                    trend="+5.4%"
                    icon={BarChart3}
                    color="text-green-500"
                />
                <QuickStat
                    label="Settlement Rate"
                    value={`${stats?.settlement_success_rate ?? (loading ? '...' : '0')}%`}
                    icon={TrendingUp}
                    color="text-purple-500"
                />
            </div>

            {/* Live Topology Map Section */}
            <section>
                <div className="flex items-center justify-between mb-4">
                    <h3 className="text-lg font-semibold flex items-center gap-2">
                        <Zap className="h-5 w-5 text-yellow-500" />
                        Grid Infrastructure Status
                    </h3>
                    <Link href="/admin/grid">
                        <Button variant="ghost" size="sm" className="text-xs gap-1">
                            Topology Details
                            <ArrowRight className="h-3 w-3" />
                        </Button>
                    </Link>
                </div>
                <GridTopologyMap />
            </section>

            {/* Admin Tools Grid */}
            <section>
                <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
                    <LayoutDashboard className="h-5 w-5 text-muted-foreground" />
                    Administrative Tools
                </h3>
                <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                    {adminTools.map((tool) => {
                        const Icon = tool.icon
                        return (
                            <Link key={tool.title} href={tool.href}>
                                <Card className={`group h-full transition-all duration-300 hover:shadow-lg hover:-translate-y-0.5 border-l-4 ${tool.borderColor} bg-card/60 backdrop-blur-sm overflow-hidden cursor-pointer`}>
                                    <CardHeader className="pb-3">
                                        <div className="flex justify-between items-start mb-2">
                                            <div className={`p-2.5 ${tool.bgColor} rounded-lg transition-transform group-hover:scale-110`}>
                                                <Icon className={`h-5 w-5 ${tool.color}`} />
                                            </div>
                                            <Badge variant="secondary" className="text-[10px] font-semibold uppercase">
                                                {tool.badge}
                                            </Badge>
                                        </div>
                                        <CardTitle className="text-lg group-hover:text-primary transition-colors flex items-center gap-2">
                                            {tool.title}
                                            <ArrowRight className="h-4 w-4 opacity-0 -translate-x-2 group-hover:opacity-100 group-hover:translate-x-0 transition-all" />
                                        </CardTitle>
                                        <CardDescription className="text-sm leading-relaxed">
                                            {tool.description}
                                        </CardDescription>
                                    </CardHeader>
                                </Card>
                            </Link>
                        )
                    })}
                </div>
            </section>

            {/* Analytics CTA */}
            <Card className="border-dashed border-2">
                <CardContent className="flex flex-col md:flex-row items-center justify-between p-6 gap-4">
                    <div className="flex items-center gap-4">
                        <div className="p-3 bg-primary/10 rounded-full">
                            <BarChart3 className="h-6 w-6 text-primary" />
                        </div>
                        <div>
                            <h3 className="font-semibold">Deep Dive Analytics</h3>
                            <p className="text-sm text-muted-foreground">View detailed metrics and zone economic insights.</p>
                        </div>
                    </div>
                    <Link href="/admin/analytics">
                        <Button className="gap-2">
                            View Analytics
                            <ArrowRight className="h-4 w-4" />
                        </Button>
                    </Link>
                </CardContent>
            </Card>
        </div>
    )
}
