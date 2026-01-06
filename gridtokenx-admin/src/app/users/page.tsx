'use client';

import { useState, useEffect } from 'react';

interface User {
    id: string;
    email: string;
    name: string;
    role: string;
    wallet_address: string | null;
    balance: number;
    locked_amount: number;
    created_at: string;
    is_verified: boolean;
}

export default function UsersPage() {
    const [users, setUsers] = useState<User[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [roleFilter, setRoleFilter] = useState('all');

    useEffect(() => {
        fetchUsers();
    }, []);

    const fetchUsers = async () => {
        setLoading(true);
        try {
            // Would fetch from API
            // const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/admin/users`);
            // const data = await res.json();

            // Mock data for demo
            setUsers([
                { id: '1', email: 'alice@example.com', name: 'Alice Johnson', role: 'user', wallet_address: '7xKX...3mN2', balance: 15000, locked_amount: 2500, created_at: '2025-12-01', is_verified: true },
                { id: '2', email: 'bob@example.com', name: 'Bob Smith', role: 'user', wallet_address: '9pL2...7xK4', balance: 8500, locked_amount: 0, created_at: '2025-12-05', is_verified: true },
                { id: '3', email: 'carol@example.com', name: 'Carol Davis', role: 'rec', wallet_address: '5mN8...2pL9', balance: 45000, locked_amount: 5000, created_at: '2025-11-20', is_verified: true },
                { id: '4', email: 'dave@example.com', name: 'Dave Wilson', role: 'user', wallet_address: null, balance: 0, locked_amount: 0, created_at: '2026-01-02', is_verified: false },
                { id: '5', email: 'eve@example.com', name: 'Eve Brown', role: 'admin', wallet_address: '3kJ7...9xM1', balance: 125000, locked_amount: 0, created_at: '2025-10-15', is_verified: true },
                { id: '6', email: 'frank@example.com', name: 'Frank Miller', role: 'user', wallet_address: '8nH4...5kJ2', balance: 3200, locked_amount: 800, created_at: '2025-12-28', is_verified: true },
            ]);
        } catch (error) {
            console.error('Failed to fetch users:', error);
        } finally {
            setLoading(false);
        }
    };

    const filteredUsers = users.filter((user) => {
        const matchesSearch =
            user.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
            user.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
            user.wallet_address?.toLowerCase().includes(searchQuery.toLowerCase());

        const matchesRole = roleFilter === 'all' || user.role === roleFilter;

        return matchesSearch && matchesRole;
    });

    const roleColors: Record<string, string> = {
        admin: 'badge-danger',
        rec: 'badge-info',
        user: 'badge-success',
    };

    return (
        <div className="space-y-6 animate-fadeIn">
            {/* Page Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold">User Management</h1>
                    <p className="text-[var(--muted)]">View and manage platform users</p>
                </div>
                <button className="btn-primary flex items-center gap-2">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                    </svg>
                    Add User
                </button>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div className="card flex items-center gap-4">
                    <div className="w-12 h-12 rounded-xl bg-[var(--primary)]/20 flex items-center justify-center text-[var(--primary)]">
                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                        </svg>
                    </div>
                    <div>
                        <p className="text-sm text-[var(--muted)]">Total Users</p>
                        <p className="text-2xl font-bold">{users.length}</p>
                    </div>
                </div>
                <div className="card flex items-center gap-4">
                    <div className="w-12 h-12 rounded-xl bg-[var(--success)]/20 flex items-center justify-center text-[var(--success)]">
                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                    </div>
                    <div>
                        <p className="text-sm text-[var(--muted)]">Verified</p>
                        <p className="text-2xl font-bold">{users.filter(u => u.is_verified).length}</p>
                    </div>
                </div>
                <div className="card flex items-center gap-4">
                    <div className="w-12 h-12 rounded-xl bg-[var(--accent)]/20 flex items-center justify-center text-[var(--accent)]">
                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" />
                        </svg>
                    </div>
                    <div>
                        <p className="text-sm text-[var(--muted)]">With Wallets</p>
                        <p className="text-2xl font-bold">{users.filter(u => u.wallet_address).length}</p>
                    </div>
                </div>
                <div className="card flex items-center gap-4">
                    <div className="w-12 h-12 rounded-xl bg-[var(--warning)]/20 flex items-center justify-center text-[var(--warning)]">
                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                    </div>
                    <div>
                        <p className="text-sm text-[var(--muted)]">Unverified</p>
                        <p className="text-2xl font-bold">{users.filter(u => !u.is_verified).length}</p>
                    </div>
                </div>
            </div>

            {/* Filters */}
            <div className="card">
                <div className="flex flex-col md:flex-row gap-4">
                    <div className="flex-1">
                        <div className="flex items-center gap-2 bg-[var(--card-hover)] rounded-lg px-4 py-2">
                            <svg className="w-5 h-5 text-[var(--muted)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                            </svg>
                            <input
                                type="text"
                                placeholder="Search by name, email, or wallet..."
                                value={searchQuery}
                                onChange={(e) => setSearchQuery(e.target.value)}
                                className="bg-transparent border-none outline-none w-full text-sm placeholder:text-[var(--muted)]"
                            />
                        </div>
                    </div>
                    <select
                        value={roleFilter}
                        onChange={(e) => setRoleFilter(e.target.value)}
                        className="bg-[var(--card-hover)] border border-[var(--border)] rounded-lg px-4 py-2"
                    >
                        <option value="all">All Roles</option>
                        <option value="user">Users</option>
                        <option value="rec">REC Authority</option>
                        <option value="admin">Admins</option>
                    </select>
                </div>
            </div>

            {/* Users Table */}
            <div className="card">
                {loading ? (
                    <div className="flex items-center justify-center py-12">
                        <div className="w-8 h-8 border-4 border-[var(--primary)] border-t-transparent rounded-full animate-spin"></div>
                    </div>
                ) : (
                    <div className="overflow-x-auto">
                        <table className="table">
                            <thead>
                                <tr>
                                    <th>User</th>
                                    <th>Role</th>
                                    <th>Wallet</th>
                                    <th>Balance</th>
                                    <th>Locked</th>
                                    <th>Status</th>
                                    <th>Joined</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {filteredUsers.map((user) => (
                                    <tr key={user.id}>
                                        <td>
                                            <div className="flex items-center gap-3">
                                                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[var(--primary)] to-[var(--accent)] flex items-center justify-center text-white font-bold">
                                                    {user.name.charAt(0)}
                                                </div>
                                                <div>
                                                    <p className="font-medium">{user.name}</p>
                                                    <p className="text-sm text-[var(--muted)]">{user.email}</p>
                                                </div>
                                            </div>
                                        </td>
                                        <td>
                                            <span className={`badge ${roleColors[user.role]}`}>
                                                {user.role}
                                            </span>
                                        </td>
                                        <td className="font-mono text-sm">
                                            {user.wallet_address || <span className="text-[var(--muted)]">Not set</span>}
                                        </td>
                                        <td className="font-medium">฿{user.balance.toLocaleString()}</td>
                                        <td className={user.locked_amount > 0 ? 'text-[var(--warning)]' : 'text-[var(--muted)]'}>
                                            ฿{user.locked_amount.toLocaleString()}
                                        </td>
                                        <td>
                                            {user.is_verified ? (
                                                <span className="badge badge-success">Verified</span>
                                            ) : (
                                                <span className="badge badge-warning">Pending</span>
                                            )}
                                        </td>
                                        <td className="text-[var(--muted)]">{user.created_at}</td>
                                        <td>
                                            <div className="flex items-center gap-2">
                                                <button className="p-2 rounded-lg hover:bg-[var(--card-hover)] transition-colors" title="View Details">
                                                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                                    </svg>
                                                </button>
                                                <button className="p-2 rounded-lg hover:bg-[var(--card-hover)] transition-colors" title="Edit User">
                                                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                                                    </svg>
                                                </button>
                                            </div>
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
