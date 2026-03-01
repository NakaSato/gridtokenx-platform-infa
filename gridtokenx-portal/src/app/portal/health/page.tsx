'use client'

import React from 'react'
import { SystemHealth } from '@/components/admin/SystemHealth'
import { AdminLayout } from '@/components/admin/AdminLayout'
import ProtectedRoute from '@/components/ProtectedRoute'

export default function AdminHealthPage() {
    return (
        <ProtectedRoute allowedRoles={['admin']}>
            <AdminLayout
                title="System Health"
                description="Monitor API gateway performance, database status, and blockchain sync."
            >
                <SystemHealth />
            </AdminLayout>
        </ProtectedRoute>
    )
}
