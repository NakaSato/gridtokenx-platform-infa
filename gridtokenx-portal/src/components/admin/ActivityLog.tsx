'use client'

import React, { useState, useMemo } from 'react'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
import { Table, TableHeader, TableBody, TableHead, TableRow, TableCell } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { Input } from '@/components/ui/input'
import {
    ClipboardList,
    Search,
    Filter,
    ArrowRightLeft,
    UserPlus,
    Key,
    ShieldAlert,
    Loader2,
    Calendar,
    RefreshCw,
    AlertCircle
} from 'lucide-react'
import { useAdminActivity, useAuth } from '@/hooks/useApi'
import { format } from 'date-fns'
import { cn } from '@/lib/utils'

function ActivitySkeleton() {
    return (
        <div className="space-y-3">
            {[...Array(6)].map((_, i) => (
                <div key={i} className="flex items-center gap-4 p-4">
                    <Skeleton className="h-10 w-10 rounded-lg" />
                    <div className="flex-1 space-y-2">
                        <Skeleton className="h-4 w-[150px]" />
                        <Skeleton className="h-3 w-[100px]" />
                    </div>
                    <Skeleton className="h-4 w-[80px]" />
                    <Skeleton className="h-4 w-[60px]" />
                </div>
            ))}
        </div>
    )
}

export function ActivityLog() {
    const { token } = useAuth()
    const { activities, loading, refetch } = useAdminActivity(token ?? undefined)
    const [searchTerm, setSearchTerm] = useState('')
    const [filterType, setFilterType] = useState<'all' | 'security' | 'auth' | 'trade'>('all')

    const filteredActivities = useMemo(() => {
        if (!activities) return []
        return activities.filter(activity => {
            const matchesSearch =
                activity.event_type.toLowerCase().includes(searchTerm.toLowerCase()) ||
                activity.user_id?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                activity.ip_address?.toLowerCase().includes(searchTerm.toLowerCase())

            const matchesType = filterType === 'all' ||
                (filterType === 'security' && (activity.event_type.includes('unauthorized') || activity.event_type.includes('failed'))) ||
                (filterType === 'auth' && (activity.event_type.includes('login') || activity.event_type.includes('register'))) ||
                (filterType === 'trade' && activity.event_type.includes('order'))

            return matchesSearch && matchesType
        })
    }, [activities, searchTerm, filterType])

    const getEventIcon = (type: string) => {
        if (type.includes('login')) return <Key className="h-4 w-4 text-blue-500" />
        if (type.includes('register')) return <UserPlus className="h-4 w-4 text-green-500" />
        if (type.includes('order')) return <ArrowRightLeft className="h-4 w-4 text-primary" />
        if (type.includes('unauthorized') || type.includes('failed')) return <ShieldAlert className="h-4 w-4 text-red-500" />
        return <ClipboardList className="h-4 w-4 text-muted-foreground" />
    }

    const getEventBadge = (type: string) => {
        if (type.includes('unauthorized') || type.includes('failed')) return 'bg-red-500/10 text-red-500'
        if (type.includes('login') || type.includes('register')) return 'bg-blue-500/10 text-blue-500'
        if (type.includes('order')) return 'bg-green-500/10 text-green-500'
        return 'bg-muted text-muted-foreground'
    }

    if (loading && !activities) {
        return <ActivitySkeleton />
    }

    return (
        <div className="space-y-6">
            {/* Filters */}
            <Card className="border-none shadow-sm">
                <CardContent className="p-4">
                    <div className="flex flex-col md:flex-row gap-4">
                        <div className="relative flex-1">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                            <Input
                                placeholder="Search by event type, user ID, or IP address..."
                                className="pl-10"
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                            />
                        </div>
                        <div className="flex gap-2">
                            {(['all', 'security', 'auth', 'trade'] as const).map((type) => (
                                <Button
                                    key={type}
                                    variant={filterType === type ? 'default' : 'outline'}
                                    size="sm"
                                    onClick={() => setFilterType(type)}
                                    className="capitalize"
                                >
                                    {type === 'all' ? 'All Events' : type}
                                </Button>
                            ))}
                            <Button variant="outline" size="sm" onClick={() => refetch()} disabled={loading}>
                                {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
                            </Button>
                        </div>
                    </div>
                </CardContent>
            </Card>

            {/* Stats */}
            <div className="flex items-center justify-between text-sm text-muted-foreground">
                <span>Showing {filteredActivities.length} events</span>
                <div className="flex gap-4">
                    <span className="flex items-center gap-1.5">
                        <div className="w-2 h-2 rounded-full bg-red-500" />
                        Security
                    </span>
                    <span className="flex items-center gap-1.5">
                        <div className="w-2 h-2 rounded-full bg-blue-500" />
                        Auth
                    </span>
                    <span className="flex items-center gap-1.5">
                        <div className="w-2 h-2 rounded-full bg-green-500" />
                        Trade
                    </span>
                </div>
            </div>

            {/* Table */}
            <Card className="border-none shadow-lg overflow-hidden">
                {filteredActivities.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-16 text-center">
                        <div className="p-4 bg-muted rounded-full mb-4">
                            <Filter className="h-8 w-8 text-muted-foreground" />
                        </div>
                        <h3 className="text-lg font-medium">No events found</h3>
                        <p className="text-sm text-muted-foreground mt-1">
                            {searchTerm || filterType !== 'all'
                                ? "No events match your filters. Try adjusting your search."
                                : "No activity recorded yet."}
                        </p>
                    </div>
                ) : (
                    <Table>
                        <TableHeader className="bg-muted/50">
                            <TableRow>
                                <TableHead className="font-semibold">Event</TableHead>
                                <TableHead className="font-semibold">Actor</TableHead>
                                <TableHead className="font-semibold">IP Address</TableHead>
                                <TableHead className="font-semibold">Time</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {filteredActivities.map((activity) => (
                                <TableRow key={activity.id} className="hover:bg-muted/30 transition-colors">
                                    <TableCell>
                                        <div className="flex items-center gap-3">
                                            <div className={cn("p-2 rounded-lg", getEventBadge(activity.event_type))}>
                                                {getEventIcon(activity.event_type)}
                                            </div>
                                            <span className="font-medium text-sm capitalize">
                                                {activity.event_type.replace(/_/g, ' ')}
                                            </span>
                                        </div>
                                    </TableCell>
                                    <TableCell className="font-mono text-xs text-muted-foreground">
                                        {activity.user_id ? `${activity.user_id.substring(0, 8)}...` : 'System'}
                                    </TableCell>
                                    <TableCell className="font-mono text-xs">{activity.ip_address || '—'}</TableCell>
                                    <TableCell>
                                        <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
                                            <Calendar className="h-3 w-3" />
                                            {format(new Date(activity.created_at), 'MMM dd, HH:mm')}
                                        </div>
                                    </TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                )}
            </Card>
        </div>
    )
}
