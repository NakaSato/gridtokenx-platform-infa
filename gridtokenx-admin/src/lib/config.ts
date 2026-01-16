export const API_CONFIG = {
    BASE_URL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000',
    TIMEOUT: 15000,
}

export function getApiUrl(path: string): string {
    if (path.startsWith('http')) return path
    return `${API_CONFIG.BASE_URL}${path.startsWith('/') ? '' : '/'}${path}`
}
