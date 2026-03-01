'use client'

import React from 'react'
import { ActivityLog } from '@/components/admin/ActivityLog'
import { AdminLayout } from '@/components/admin/AdminLayout'
import ProtectedRoute from '@/components/ProtectedRoute'

export default function AdminActivityPage() {
    return (
        <ProtectedRoute allowedRoles={['admin']}>
            <AdminLayout
                title="Activity Log"
                description="Comprehensive audit trail of security and operational events."
            >
                <ActivityLog />
            </AdminLayout>
        </ProtectedRoute>
    )
}
