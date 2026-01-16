/**
 * API Client for GridTokenX Admin Portal
 */

import { API_CONFIG, getApiUrl } from './config'

export interface ApiRequestOptions {
    method?: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH'
    headers?: Record<string, string>
    body?: any
    token?: string
}

export interface ApiResponse<T = any> {
    data?: T
    error?: string
    status: number
}

// -- Response Types for Admin API --

export interface AdminStatsResponse {
    total_users: number
    total_orders: number
    total_volume_kwh: number
    total_revenue?: number
}

export interface AuditEventRecord {
    id: string
    user_id?: string
    action: string
    status: string
    created_at: string
    metadata?: any
}

export interface DetailedHealthStatus {
    system: {
        status: string
        active_requests: number
    }
    checks: {
        database: string
        blockchain: string
        redis: string
    }
}

/**
 * Make an API request using native fetch
 */
export async function apiRequest<T = any>(
    path: string,
    options: ApiRequestOptions = {}
): Promise<ApiResponse<T>> {
    const { method = 'GET', headers = {}, body, token } = options
    const url = getApiUrl(path)

    const requestHeaders: Record<string, string> = {
        'Content-Type': 'application/json',
        ...headers,
    }

    if (token) {
        requestHeaders.Authorization = `Bearer ${token}`
    }

    try {
        const response = await fetch(url, {
            method,
            headers: requestHeaders,
            body: body ? JSON.stringify(body) : undefined,
        })

        const text = await response.text()
        let data: any = {}
        if (text) {
            try {
                data = JSON.parse(text)
            } catch (e) {
                return { error: `Invalid JSON: ${text}`, status: response.status }
            }
        }

        if (!response.ok) {
            return {
                error: data.message || data.error || 'Request failed',
                status: response.status,
            }
        }

        return { data, status: response.status }
    } catch (error) {
        return {
            error: error instanceof Error ? error.message : 'Unknown error',
            status: 500,
        }
    }
}

export class ApiClient {
    private token?: string

    constructor(token?: string) {
        this.token = token
    }

    setToken(token: string) {
        this.token = token
    }

    clearToken() {
        this.token = undefined
    }

    async getAdminStats(): Promise<ApiResponse<AdminStatsResponse>> {
        return apiRequest<AdminStatsResponse>('/api/v1/analytics/admin/stats', {
            method: 'GET',
            token: this.token
        })
    }

    async getRecentActivity(): Promise<ApiResponse<AuditEventRecord[]>> {
        return apiRequest<AuditEventRecord[]>('/api/v1/analytics/admin/activity', {
            method: 'GET',
            token: this.token
        })
    }

    async getSystemHealth(): Promise<ApiResponse<DetailedHealthStatus>> {
        return apiRequest<DetailedHealthStatus>('/api/v1/analytics/admin/health', {
            method: 'GET',
            token: this.token
        })
    }
}

// Export singleton instance
export const defaultApiClient = new ApiClient()
