'use client'

import React from 'react'
import { VppDashboard } from '@/components/admin/VppDashboard'
import { AdminLayout } from '@/components/admin/AdminLayout'
import ProtectedRoute from '@/components/ProtectedRoute'

export default function VppOrchestrationPage() {
    return (
        <ProtectedRoute allowedRoles={['admin']}>
            <AdminLayout
                title="VPP Orchestration"
                description="Manage Virtual Power Plant clusters and trigger grid balancing dispatches."
            >
                <VppDashboard />
            </AdminLayout>
        </ProtectedRoute>
    )
}
