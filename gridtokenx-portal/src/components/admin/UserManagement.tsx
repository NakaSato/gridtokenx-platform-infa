'use client'

import React, { useState } from 'react'
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from '@/components/ui/card'
import { Table, TableHeader, TableBody, TableHead, TableRow, TableCell } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import {
    Users,
    Search,
    Filter,
    Shield,
    Mail,
    Calendar,
    MoreHorizontal,
    Loader2,
    CheckCircle2,
    XCircle,
    UserCheck,
    UserX
} from 'lucide-react'
import { useAdminUsers, useAuth, useAdminActions } from '@/hooks/useApi'
import { Input } from '@/components/ui/input'
import { format } from 'date-fns'
import { Button } from '@/components/ui/button'
import { toast } from 'react-hot-toast'
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { Skeleton } from "@/components/ui/skeleton"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"

function UserTableSkeleton() {
    return (
        <div className="space-y-3">
            {[...Array(5)].map((_, i) => (
                <div key={i} className="flex items-center gap-4 p-4">
                    <Skeleton className="h-12 w-12 rounded-full" />
                    <div className="flex-1 space-y-2">
                        <Skeleton className="h-4 w-[200px]" />
                        <Skeleton className="h-3 w-[150px]" />
                    </div>
                    <Skeleton className="h-8 w-[100px]" />
                    <Skeleton className="h-8 w-[80px]" />
                </div>
            ))}
        </div>
    )
}

function EmptyState({ message }: { message: string }) {
    return (
        <div className="flex flex-col items-center justify-center py-16 text-center">
            <div className="p-4 bg-muted rounded-full mb-4">
                <Users className="h-8 w-8 text-muted-foreground" />
            </div>
            <h3 className="text-lg font-medium">No users found</h3>
            <p className="text-sm text-muted-foreground mt-1 max-w-sm">{message}</p>
        </div>
    )
}

export function UserManagement() {
    const { token } = useAuth()
    const { users: usersResponse, loading, refetch } = useAdminUsers(token ?? undefined)
    const users = usersResponse?.users ?? []
    const total = usersResponse?.total ?? 0
    const { updateRole, deactivateUser, reactivateUser, loading: actionLoading } = useAdminActions(token ?? undefined)
    const [searchTerm, setSearchTerm] = useState('')
    const [roleFilter, setRoleFilter] = useState<string>('all')
    const [statusFilter, setStatusFilter] = useState<string>('all')

    const filteredUsers = users?.filter(user => {
        const matchesSearch = user.username.toLowerCase().includes(searchTerm.toLowerCase()) ||
            user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
            user.wallet_address?.toLowerCase().includes(searchTerm.toLowerCase())

        const matchesRole = roleFilter === 'all' || user.role.toLowerCase() === roleFilter.toLowerCase()
        const matchesStatus = statusFilter === 'all' ||
            (statusFilter === 'active' && user.is_active) ||
            (statusFilter === 'inactive' && !user.is_active)

        return matchesSearch && matchesRole && matchesStatus
    }) || []

    const handleRoleUpdate = async (userId: string, currentRole: string) => {
        const nextRole = currentRole === 'admin' ? 'user' : 'admin'
        const result = await updateRole(userId, nextRole)
        if (result) {
            toast.success(`User role updated to ${nextRole}`)
            refetch()
        }
    }

    const handleToggleStatus = async (userId: string, isActive: boolean) => {
        const result = isActive ? await deactivateUser(userId) : await reactivateUser(userId)
        if (result) {
            toast.success(`User account ${isActive ? 'deactivated' : 'reactivated'}`)
            refetch()
        }
    }

    const getRoleBadge = (role: string) => {
        switch (role.toLowerCase()) {
            case 'admin':
                return <Badge className="bg-red-500/10 text-red-500 border-red-500/20">Admin</Badge>
            case 'vpp_operator':
                return <Badge className="bg-yellow-500/10 text-yellow-500 border-yellow-500/20">Operator</Badge>
            default:
                return <Badge variant="outline">{role}</Badge>
        }
    }

    if (loading && !users) {
        return (
            <div className="flex h-96 items-center justify-center">
                <Loader2 className="h-10 w-10 animate-spin text-primary" />
                <span className="ml-3 text-lg font-medium">Scanning Platform Directory...</span>
            </div>
        )
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
                                placeholder="Search users by name, email, or wallet..."
                                className="pl-10"
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                            />
                        </div>
                        <div className="flex gap-2">
                            <Select value={roleFilter} onValueChange={setRoleFilter}>
                                <SelectTrigger className="w-[140px]">
                                    <SelectValue placeholder="Role" />
                                </SelectTrigger>
                                <SelectContent>
                                    <SelectItem value="all">All Roles</SelectItem>
                                    <SelectItem value="admin">Admin</SelectItem>
                                    <SelectItem value="user">User</SelectItem>
                                    <SelectItem value="vpp_operator">Operator</SelectItem>
                                </SelectContent>
                            </Select>
                            <Select value={statusFilter} onValueChange={setStatusFilter}>
                                <SelectTrigger className="w-[140px]">
                                    <SelectValue placeholder="Status" />
                                </SelectTrigger>
                                <SelectContent>
                                    <SelectItem value="all">All Status</SelectItem>
                                    <SelectItem value="active">Active</SelectItem>
                                    <SelectItem value="inactive">Inactive</SelectItem>
                                </SelectContent>
                            </Select>
                            <Button variant="outline" onClick={() => refetch()} disabled={loading}>
                                {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Filter className="h-4 w-4" />}
                            </Button>
                        </div>
                    </div>
                </CardContent>
            </Card>

            {/* Stats */}
            <div className="flex items-center justify-between text-sm text-muted-foreground">
                <span>Showing {filteredUsers.length} of {total} users</span>
                <div className="flex gap-4">
                    <span className="flex items-center gap-1.5">
                        <div className="w-2 h-2 rounded-full bg-green-500" />
                        Active
                    </span>
                    <span className="flex items-center gap-1.5">
                        <div className="w-2 h-2 rounded-full bg-red-500" />
                        Inactive
                    </span>
                </div>
            </div>

            {/* Table */}
            <Card className="border-none shadow-lg overflow-hidden">
                {loading && !users ? (
                    <UserTableSkeleton />
                ) : filteredUsers.length === 0 ? (
                    <EmptyState message={searchTerm || roleFilter !== 'all' || statusFilter !== 'all'
                        ? "No users match your filters. Try adjusting your search criteria."
                        : "No users registered yet."} />
                ) : (
                    <Table>
                        <TableHeader className="bg-muted/50">
                            <TableRow>
                                <TableHead className="font-semibold">User</TableHead>
                                <TableHead className="font-semibold">Role</TableHead>
                                <TableHead className="font-semibold">Wallet Address</TableHead>
                                <TableHead className="font-semibold">Status</TableHead>
                                <TableHead className="font-semibold text-right">Actions</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {filteredUsers.map((user) => (
                                <TableRow key={user.id} className="hover:bg-muted/50 transition-colors">
                                    <TableCell>
                                        <div className="flex flex-col">
                                            <span className="font-medium">{user.username}</span>
                                            <span className="text-xs text-muted-foreground flex items-center gap-1">
                                                <Mail className="h-3 w-3" />
                                                {user.email}
                                            </span>
                                        </div>
                                    </TableCell>
                                    <TableCell>{getRoleBadge(user.role)}</TableCell>
                                    <TableCell className="font-mono text-xs text-muted-foreground">
                                        {user.wallet_address ? `${user.wallet_address.substring(0, 8)}...${user.wallet_address.substring(user.wallet_address.length - 8)}` : 'Not Linked'}
                                    </TableCell>
                                    <TableCell>
                                        {user.is_active ? (
                                            <div className="flex items-center gap-1.5 text-xs text-green-600">
                                                <CheckCircle2 className="h-3.5 w-3.5" />
                                                Active
                                            </div>
                                        ) : (
                                            <div className="flex items-center gap-1.5 text-xs text-red-500">
                                                <XCircle className="h-3.5 w-3.5" />
                                                Inactive
                                            </div>
                                        )}
                                    </TableCell>
                                    <TableCell className="text-right">
                                        <DropdownMenu>
                                            <DropdownMenuTrigger asChild>
                                                <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                                                    <MoreHorizontal className="h-4 w-4" />
                                                </Button>
                                            </DropdownMenuTrigger>
                                            <DropdownMenuContent align="end">
                                                <DropdownMenuLabel>Actions</DropdownMenuLabel>
                                                <DropdownMenuItem onClick={() => navigator.clipboard.writeText(user.id)}>
                                                    Copy ID
                                                </DropdownMenuItem>
                                                <DropdownMenuSeparator />
                                                <DropdownMenuItem
                                                    onClick={() => handleRoleUpdate(user.id, user.role)}
                                                    disabled={actionLoading}
                                                >
                                                    {user.role === 'admin' ? (
                                                        <><UserX className="h-4 w-4 mr-2" /> Demote to User</>
                                                    ) : (
                                                        <><UserCheck className="h-4 w-4 mr-2" /> Promote to Admin</>
                                                    )}
                                                </DropdownMenuItem>
                                                <DropdownMenuItem
                                                    className={user.is_active ? "text-red-500" : "text-green-500"}
                                                    onClick={() => handleToggleStatus(user.id, user.is_active)}
                                                    disabled={actionLoading}
                                                >
                                                    {user.is_active ? 'Deactivate' : 'Reactivate'}
                                                </DropdownMenuItem>
                                            </DropdownMenuContent>
                                        </DropdownMenu>
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
