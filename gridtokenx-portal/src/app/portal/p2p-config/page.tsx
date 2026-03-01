'use client'

import React from 'react'
import { P2PConfigDashboard } from '@/components/admin/P2PConfigDashboard'
import { AdminLayout } from '@/components/admin/AdminLayout'
import ProtectedRoute from '@/components/ProtectedRoute'

export default function P2PConfigPage() {
    return (
        <ProtectedRoute allowedRoles={['admin']}>
            <AdminLayout>
                <P2PConfigDashboard />
            </AdminLayout>
        </ProtectedRoute>
    )
}
