'use client'

import React, { useState } from 'react'
import {
    useVppClusters,
    useDispatchVppCluster,
    useAuth
} from '@/hooks/useApi'
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from '@/components/ui/card'
import { Table, TableHeader, TableBody, TableHead, TableRow, TableCell } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import {
    Loader2,
    Zap,
    Activity,
    Battery,
    Heart,
    Send,
    RefreshCw,
    AlertCircle,
    LayoutGrid
} from 'lucide-react'
import { Progress } from '@/components/ui/progress'
import { toast } from 'react-hot-toast'

export function VppDashboard() {
    const { token } = useAuth()
    const { clusters, loading: clustersLoading, error: clustersError, refetch } = useVppClusters(token ?? undefined)
    const { dispatch, loading: dispatchLoading } = useDispatchVppCluster(token ?? undefined)
    const [dispatchTargets, setDispatchTargets] = useState<Record<string, string>>({})

    const handleDispatch = async (clusterId: string) => {
        const target = dispatchTargets[clusterId]
        if (!target) {
            toast.error('Please enter a target kW value')
            return
        }

        const value = parseFloat(target)
        if (isNaN(value)) {
            toast.error('Invalid kW value')
            return
        }

        const result = await dispatch(clusterId, value)
        if (result) {
            toast.success(`Successfully dispatched ${clusterId} to ${value} kW`)
            refetch()
        } else {
            toast.error('Dispatch failed')
        }
    }

    if (clustersLoading) {
        return (
            <div className="flex h-96 items-center justify-center">
                <Loader2 className="h-12 w-12 animate-spin text-primary" />
                <span className="ml-4 text-xl font-medium">Synchronizing VPP Clusters...</span>
            </div>
        )
    }

    return (
        <div className="space-y-8 p-8 bg-background max-w-7xl mx-auto">
            <header className="flex justify-between items-center bg-card p-8 rounded-2xl border shadow-lg backdrop-blur-xl bg-opacity-80">
                <div className="flex items-center gap-6">
                    <div className="p-4 bg-yellow-500/10 rounded-2xl">
                        <Zap className="h-10 w-10 text-yellow-500" />
                    </div>
                    <div>
                        <h1 className="text-4xl font-extrabold tracking-tight">VPP Orchestration</h1>
                        <p className="text-muted-foreground mt-2 text-lg">Manage Virtual Power Plant clusters for grid balancing.</p>
                    </div>
                </div>
                <div className="flex gap-4">
                    <Button variant="outline" size="lg" onClick={() => refetch()} className="flex gap-2">
                        <RefreshCw className={`h-5 w-5 ${clustersLoading ? 'animate-spin' : ''}`} />
                        Refresh Status
                    </Button>
                    <Badge variant="outline" className="text-lg font-bold px-4 py-2 bg-yellow-500/5 border-yellow-500/20 text-yellow-600">
                        System Operational
                    </Badge>
                </div>
            </header>

            {/* Cluster Monitoring Table */}
            <Card className="border-none shadow-2xl overflow-hidden bg-white/5 backdrop-blur-md">
                <CardHeader className="border-b border-white/10 bg-muted/20">
                    <div className="flex justify-between items-center">
                        <div>
                            <CardTitle className="text-2xl flex items-center gap-2">
                                <LayoutGrid className="h-6 w-6 text-primary" />
                                Active Clusters
                            </CardTitle>
                            <CardDescription>Real-time telemetry and dispatch controls for VPP resources.</CardDescription>
                        </div>
                        <div className="text-right">
                            <span className="text-sm text-muted-foreground">Total Capacity:</span>
                            <div className="text-xl font-bold text-primary">
                                {clusters?.reduce((acc, c) => acc + c.total_capacity_kwh, 0).toFixed(1)} kWh
                            </div>
                        </div>
                    </div>
                </CardHeader>
                <CardContent className="p-0">
                    <Table>
                        <TableHeader className="bg-muted/30">
                            <TableRow className="hover:bg-transparent border-white/5">
                                <TableHead className="py-6 font-bold text-md">Cluster ID</TableHead>
                                <TableHead className="py-6 font-bold text-md">Status (SOC)</TableHead>
                                <TableHead className="py-6 font-bold text-md">Resources</TableHead>
                                <TableHead className="py-6 font-bold text-md">Flexibility</TableHead>
                                <TableHead className="py-6 font-bold text-md text-right">Dispatch Control (kW)</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {clusters?.length === 0 ? (
                                <TableRow>
                                    <TableCell colSpan={5} className="h-48 text-center bg-muted/5">
                                        <div className="flex flex-col items-center justify-center gap-2 text-muted-foreground">
                                            <AlertCircle className="h-10 w-10 opacity-20" />
                                            <p className="text-lg">No active VPP clusters identified by the gateway.</p>
                                        </div>
                                    </TableCell>
                                </TableRow>
                            ) : (
                                clusters?.map((cluster) => (
                                    <TableRow key={cluster.cluster_id} className="hover:bg-white/5 transition-all duration-300 border-white/5 group">
                                        <TableCell className="py-6">
                                            <div className="font-bold text-lg">{cluster.cluster_id}</div>
                                            <div className="flex items-center gap-1.5 mt-1 text-xs text-muted-foreground">
                                                <Heart className="h-3 w-3 text-red-500 fill-red-500" />
                                                Health: {cluster.health_score.toFixed(1)}%
                                            </div>
                                        </TableCell>
                                        <TableCell className="py-6 min-w-[200px]">
                                            <div className="flex items-center justify-between mb-2">
                                                <div className="flex items-center gap-2">
                                                    <Battery className={`h-4 w-4 ${cluster.soc_percentage < 20 ? 'text-red-500' : 'text-green-500'}`} />
                                                    <span className="font-bold">{cluster.soc_percentage.toFixed(1)}%</span>
                                                </div>
                                                <span className="text-xs text-muted-foreground">
                                                    {cluster.current_stored_kwh.toFixed(1)} / {cluster.total_capacity_kwh.toFixed(1)} kWh
                                                </span>
                                            </div>
                                            <Progress value={cluster.soc_percentage} className="h-2 bg-white/10" />
                                        </TableCell>
                                        <TableCell className="py-6">
                                            <div className="flex gap-2">
                                                <Badge variant="secondary" className="bg-blue-500/10 text-blue-500 hover:bg-blue-500/20">
                                                    {cluster.resource_count} Meters
                                                </Badge>
                                                <Badge variant="secondary" className="bg-purple-500/10 text-purple-500 hover:bg-purple-500/20">
                                                    {cluster.controllable_count} Controllable
                                                </Badge>
                                            </div>
                                        </TableCell>
                                        <TableCell className="py-6">
                                            <div className="space-y-1">
                                                <div className="text-xs flex justify-between">
                                                    <span className="text-muted-foreground">Flex Up:</span>
                                                    <span className="font-medium text-green-500">+{cluster.flex_up_kw.toFixed(1)} kW</span>
                                                </div>
                                                <div className="text-xs flex justify-between">
                                                    <span className="text-muted-foreground">Flex Down:</span>
                                                    <span className="font-medium text-red-500">-{cluster.flex_down_kw.toFixed(1)} kW</span>
                                                </div>
                                            </div>
                                        </TableCell>
                                        <TableCell className="py-6 text-right">
                                            <div className="flex justify-end items-center gap-3">
                                                <Input
                                                    placeholder="Target kW"
                                                    className="w-32 bg-white/5 border-white/10 focus:border-primary/50 text-right font-mono"
                                                    type="number"
                                                    value={dispatchTargets[cluster.cluster_id] || ''}
                                                    onChange={(e) => setDispatchTargets({
                                                        ...dispatchTargets,
                                                        [cluster.cluster_id]: e.target.value
                                                    })}
                                                />
                                                <Button
                                                    size="lg"
                                                    disabled={dispatchLoading}
                                                    onClick={() => handleDispatch(cluster.cluster_id)}
                                                    className="bg-primary hover:bg-primary-hover shadow-lg shadow-primary/20 flex gap-2 font-bold px-6"
                                                >
                                                    {dispatchLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Send className="h-4 w-4" />}
                                                    Dispatch
                                                </Button>
                                            </div>
                                        </TableCell>
                                    </TableRow>
                                ))
                            )}
                        </TableBody>
                    </Table>
                </CardContent>
            </Card>
        </div>
    )
}
