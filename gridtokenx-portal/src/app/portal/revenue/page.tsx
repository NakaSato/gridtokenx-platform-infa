'use client'

import React from 'react'
import { RevenueDashboard } from '@/components/admin/RevenueDashboard'
import { AdminLayout } from '@/components/admin/AdminLayout'
import ProtectedRoute from '@/components/ProtectedRoute'

export default function AdminRevenuePage() {
    return (
        <ProtectedRoute allowedRoles={['admin']}>
            <AdminLayout
                title="Platform Revenue"
                description="Real-time overview of on-chain trading fees and platform income."
            >
                <RevenueDashboard />
            </AdminLayout>
        </ProtectedRoute>
    )
}
