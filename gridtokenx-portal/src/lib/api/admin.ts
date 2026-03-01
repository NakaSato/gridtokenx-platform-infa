import { apiRequest, ApiResponse } from './core'
import { getApiUrl } from '../config'

export class AdminApi {
    constructor(private getToken: () => string | undefined) { }

    async getRevenueSummary(): Promise<ApiResponse<import('../../types/trading').PlatformRevenueSummary>> {
        return apiRequest<import('../../types/trading').PlatformRevenueSummary>('/api/v1/trading/revenue/summary', {
            method: 'GET',
            token: this.getToken(),
        })
    }

    async getRevenueRecords(limit = 50, offset = 0): Promise<ApiResponse<import('../../types/trading').RevenueRecord[]>> {
        const params = new URLSearchParams({ limit: limit.toString(), offset: offset.toString() })
        return apiRequest<import('../../types/trading').RevenueRecord[]>(`/api/v1/trading/revenue/records?${params.toString()}`, {
            method: 'GET',
            token: this.getToken(),
        })
    }

    async getVppClusters(): Promise<ApiResponse<import('../../types/grid').VppClusterStatus[]>> {
        return apiRequest<import('../../types/grid').VppClusterStatus[]>('/api/v1/vpp/clusters', {
            method: 'GET',
            token: this.getToken(),
        })
    }

    async dispatchVppCluster(clusterId: string, targetKw: number): Promise<ApiResponse<import('../../types/grid').VppDispatchResponse>> {
        return apiRequest<import('../../types/grid').VppDispatchResponse>('/api/v1/vpp/dispatch', {
            method: 'POST',
            body: { cluster_id: clusterId, target_kw: targetKw },
            token: this.getToken(),
        })
    }

    async getAdminStats(): Promise<ApiResponse<import('../../types/trading').AdminStatsResponse>> {
        return apiRequest<import('../../types/trading').AdminStatsResponse>('/api/v1/analytics/admin/stats', {
            method: 'GET',
            token: this.getToken(),
        })
    }

    async getSystemHealth(): Promise<ApiResponse<import('../../types/trading').DetailedHealthStatus>> {
        return apiRequest<import('../../types/trading').DetailedHealthStatus>('/api/v1/analytics/admin/health', {
            method: 'GET',
            token: this.getToken(),
        })
    }

    async getAdminActivity(): Promise<ApiResponse<import('../../types/trading').AuditEventRecord[]>> {
        return apiRequest<import('../../types/trading').AuditEventRecord[]>('/api/v1/analytics/admin/activity', {
            method: 'GET',
            token: this.getToken(),
        })
    }

    async getZoneEconomicInsights(timeframe: string = '24h'): Promise<ApiResponse<import('../../types/trading').ZoneEconomicInsights>> {
        return apiRequest<import('../../types/trading').ZoneEconomicInsights>(`/api/v1/analytics/admin/zones/economic?timeframe=${timeframe}`, {
            method: 'GET',
            token: this.getToken(),
        })
    }

    async getGridTopology(): Promise<ApiResponse<import('../../types/grid').GridTopologyResponse>> {
        return apiRequest<import('../../types/grid').GridTopologyResponse>('/api/v1/analytics/admin/topology', {
            method: 'GET',
            token: this.getToken(),
        })
    }

    async getAdminUsers(filters?: any): Promise<ApiResponse<import('../../types/trading').AdminUsersResponse>> {
        const params = new URLSearchParams(filters)
        return apiRequest<import('../../types/trading').AdminUsersResponse>(`/api/v1/admin/users?${params.toString()}`, {
            method: 'GET',
            token: this.getToken(),
        })
    }

    async updateUserRole(userId: string, role: string): Promise<ApiResponse<import('../../types/trading').AdminUser>> {
        return apiRequest<import('../../types/trading').AdminUser>(`/api/v1/admin/users/${userId}/role`, {
            method: 'PUT',
            token: this.getToken(),
            body: JSON.stringify({ role }), // Must be JSON according to original structure
        })
    }

    async deactivateUser(userId: string): Promise<ApiResponse<import('../../types/trading').AdminUser>> {
        return apiRequest<import('../../types/trading').AdminUser>(`/api/v1/admin/users/${userId}/deactivate`, {
            method: 'POST',
            token: this.getToken(),
        })
    }

    async reactivateUser(userId: string): Promise<ApiResponse<import('../../types/trading').AdminUser>> {
        return apiRequest<import('../../types/trading').AdminUser>(`/api/v1/admin/users/${userId}/reactivate`, {
            method: 'POST',
            token: this.getToken(),
        })
    }

    async exportTradingHistory(format: 'csv' | 'json', filters?: any): Promise<ApiResponse<Blob>> {
        const params = new URLSearchParams(filters)
        const url = `/api/v1/trading/export/${format}?${params.toString()}`
        const apiUrl = getApiUrl(url)

        try {
            const response = await fetch(apiUrl, {
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${this.getToken()}`,
                }
            })
            if (!response.ok) throw new Error('Export failed')
            const blob = await response.blob()
            return { data: blob as any, status: response.status }
        } catch (e) {
            return { error: e instanceof Error ? e.message : 'Export failed', status: 500 }
        }
    }

    // P2P Config Management
    async getP2PConfigs(): Promise<ApiResponse<any>> {
        return apiRequest<any>('/api/v1/analytics/admin/p2p-config', {
            method: 'GET',
            token: this.getToken(),
        })
    }

    async updateP2PConfig(key: string, value: number, reason?: string): Promise<ApiResponse<any>> {
        return apiRequest<any>(`/api/v1/analytics/admin/p2p-config/${key}`, {
            method: 'PUT',
            token: this.getToken(),
            body: { value, reason },
        })
    }

    async getP2PConfigAudit(key?: string, limit = 50): Promise<ApiResponse<any>> {
        const url = key
            ? `/api/v1/analytics/admin/p2p-config/${key}/audit?limit=${limit}`
            : `/api/v1/analytics/admin/p2p-config/audit?limit=${limit}`;
        return apiRequest<any>(url, {
            method: 'GET',
            token: this.getToken(),
        })
    }
}
