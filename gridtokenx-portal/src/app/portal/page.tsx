'use client'

import React from 'react'
import { AdminPortal } from '@/components/admin/AdminPortal'
import { AdminLayout } from '@/components/admin/AdminLayout'
import ProtectedRoute from '@/components/ProtectedRoute'

export default function AdminPage() {
    return (
        <ProtectedRoute allowedRoles={['admin']}>
            <AdminLayout>
                <AdminPortal />
            </AdminLayout>
        </ProtectedRoute>
    )
}
