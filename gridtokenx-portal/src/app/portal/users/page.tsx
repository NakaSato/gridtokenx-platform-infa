'use client'

import React from 'react'
import { UserManagement } from '@/components/admin/UserManagement'
import { AdminLayout } from '@/components/admin/AdminLayout'
import ProtectedRoute from '@/components/ProtectedRoute'

export default function AdminUsersPage() {
    return (
        <ProtectedRoute allowedRoles={['admin']}>
            <AdminLayout
                title="User Management"
                description="Manage platform identities, roles, and on-chain linkages."
            >
                <UserManagement />
            </AdminLayout>
        </ProtectedRoute>
    )
}
