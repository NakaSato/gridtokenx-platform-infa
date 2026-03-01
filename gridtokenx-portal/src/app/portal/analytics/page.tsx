'use client'

import React from 'react'
import { AdminAnalytics } from '@/components/admin/AdminAnalytics'
import { AdminLayout } from '@/components/admin/AdminLayout'
import ProtectedRoute from '@/components/ProtectedRoute'

export default function AdminAnalyticsPage() {
    return (
        <ProtectedRoute allowedRoles={['admin']}>
            <AdminLayout
                title="Platform Analytics"
                description="Comprehensive economic insights and distribution metrics."
            >
                <AdminAnalytics />
            </AdminLayout>
        </ProtectedRoute>
    )
}
