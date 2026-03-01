/**
 * API Client for GridTokenX Platform
 * Refactored into a Facade pattern over modular domain APIs
 */

import { AuthApi } from './api/auth'
import { AdminApi } from './api/admin'
export type { ApiRequestOptions, ApiResponse } from './api/core'
export { apiRequest } from './api/core'

/**
 * Main API Client Facade class
 * Maintains perfect backward compatibility with existing codebase
 */
export class ApiClient {
  private token?: string

  // Domain API Modules
  private authApi: AuthApi
  private adminApi: AdminApi

  constructor(token?: string) {
    this.token = token

    // Provide a dynamic token getter to the domain modules
    const getToken = () => this.token

    this.authApi = new AuthApi(getToken)
    this.adminApi = new AdminApi(getToken)
  }

  setToken(token: string): void {
    this.token = token
  }

  clearToken(): void {
    this.token = undefined
  }

  // ==========================================
  // AUTHENTICATION & PROFILE
  // ==========================================

  async login(username: string, password: string) { return this.authApi.login(username, password) }
  async register(userData: any) { return this.authApi.register(userData) }
  async verifyWalletSignature(data: any) { return this.authApi.verifyWalletSignature(data) }
  async logout() { return this.authApi.logout() }
  async updateWallet(walletAddress: string, verifyOwnership?: boolean) { return this.authApi.updateWallet(walletAddress, verifyOwnership) }
  async verifyEmail(token: string) { return this.authApi.verifyEmail(token) }
  async resendVerification(email: string) { return this.authApi.resendVerification(email) }
  async forgotPassword(email: string) { return this.authApi.forgotPassword(email) }
  async resetPassword(token: string, newPassword: string) { return this.authApi.resetPassword(token, newPassword) }

  // ==========================================
  // TRADING & RECURRING & ALERTS
  // ==========================================

  // async createOrder(orderData: any) { return this.tradingApi.createOrder(orderData) }
  // async getOrders(filters?: any) { return this.tradingApi.getOrders(filters) }
  // async getOrderBook(filters?: any) { return this.tradingApi.getOrderBook(filters) }
  // async getMarketData() { return this.tradingApi.getMarketData() }
  // async getTrades(filters?: any) { return this.tradingApi.getTrades(filters) }
  // async cancelOrder(orderId: string) { return this.tradingApi.cancelOrder(orderId) }

  // P2P 
  // async createP2POrder(orderData: any) { return this.tradingApi.createP2POrder(orderData) }
  // async getP2POrderBook() { return this.tradingApi.getP2POrderBook() }
  // async getMyP2POrders() { return this.tradingApi.getMyP2POrders() }
  // async getMatchingStatus() { return this.tradingApi.getMatchingStatus() }
  // async getSettlementStats() { return this.tradingApi.getSettlementStats() }
  // async calculateP2PCost(request: any) { return this.tradingApi.calculateP2PCost(request) }
  // async getP2PMarketPrices() { return this.tradingApi.getP2PMarketPrices() }
  // async getTradeHistory(filters?: any) { return this.tradingApi.getTradeHistory(filters) }

  // Alerts & Recurring
  // async createPriceAlert(data: any) { return this.tradingApi.createPriceAlert(data) }
  // async listPriceAlerts() { return this.tradingApi.listPriceAlerts() }
  // async deletePriceAlert(id: string) { return this.tradingApi.deletePriceAlert(id) }
  // async createRecurringOrder(data: any) { return this.tradingApi.createRecurringOrder(data) }
  // async listRecurringOrders() { return this.tradingApi.listRecurringOrders() }
  // async getRecurringOrder(id: string) { return this.tradingApi.getRecurringOrder(id) }
  // async cancelRecurringOrder(id: string) { return this.tradingApi.cancelRecurringOrder(id) }
  // async pauseRecurringOrder(id: string) { return this.tradingApi.pauseRecurringOrder(id) }
  // async resumeRecurringOrder(id: string) { return this.tradingApi.resumeRecurringOrder(id) }

  // ==========================================
  // USER (WALLETS, BALANCE, NOTIFICATIONS)
  async getProfile() { return this.authApi.getProfile() }
  async updateProfile(profileData: any) { return this.authApi.updateProfile(profileData) }
  // async getBalance(walletAddress?: string) { return this.userApi.getBalance(walletAddress) }
  // async getUserAnalytics(params: any) { return this.userApi.getUserAnalytics(params) }
  // async getUserHistory(params: any) { return this.userApi.getUserHistory(params) }
  // async getUserTransactions(filters?: any) { return this.userApi.getUserTransactions(filters) }

  // Multi-wallet
  // async listWallets() { return this.userApi.listWallets() }
  // async linkWallet(data: any) { return this.userApi.linkWallet(data) }
  // async removeWallet(walletId: string) { return this.userApi.removeWallet(walletId) }
  // async setPrimaryWallet(walletId: string) { return this.userApi.setPrimaryWallet(walletId) }

  // Notifications
  // async listNotifications(filters?: any) { return this.userApi.listNotifications(filters) }
  // async markNotificationAsRead(id: string) { return this.userApi.markNotificationAsRead(id) }
  // async markAllNotificationsAsRead() { return this.userApi.markAllNotificationsAsRead() }
  // async getNotificationPreferences() { return this.userApi.getNotificationPreferences() }
  // async updateNotificationPreferences(data: any) { return this.userApi.updateNotificationPreferences(data) }

  // ==========================================
  // METERS & GRID
  // ==========================================

  // async submitMeterData(data: any) { return this.metersApi.submitMeterData(data) }
  // async getMeterStats() { return this.metersApi.getMeterStats() }
  // async getMyReadings(limit?: number, offset?: number) { return this.metersApi.getMyReadings(limit, offset) }
  // async getMyMeters() { return this.metersApi.getMyMeters() }
  // async registerMeter(data: any) { return this.metersApi.registerMeter(data) }
  // async mintReading(readingId: string) { return this.metersApi.mintReading(readingId) }
  // async getGridStatus() { return this.metersApi.getGridStatus() }
  // async getGridTopology() { return this.metersApi.getGridTopology() }
  // async getPublicMeters() { return this.metersApi.getPublicMeters() }
  // async getGridHistory(limit?: number) { return this.metersApi.getGridHistory(limit) }

  // ==========================================
  // CARBON CREDITS
  // ==========================================

  // async getCarbonBalance() { return this.carbonApi.getCarbonBalance() }
  // async getCarbonHistory() { return this.carbonApi.getCarbonHistory() }
  // async getCarbonTransactions() { return this.carbonApi.getCarbonTransactions() }
  // async transferCarbonCredits(data: any) { return this.carbonApi.transferCarbonCredits(data) }

  // ==========================================
  // FUTURES
  // ==========================================

  // async getPositions() { return this.futuresApi.getPositions() }
  // async getFuturesProducts() { return this.futuresApi.getFuturesProducts() }
  // async createFuturesOrder(data: any) { return this.futuresApi.createFuturesOrder(data) }
  // async getFuturesPositions() { return this.futuresApi.getFuturesPositions() }
  // async getFuturesCandles(productId: string, interval?: string) { return this.futuresApi.getFuturesCandles(productId, interval) }
  // async getFuturesOrderBook(productId: string) { return this.futuresApi.getFuturesOrderBook(productId) }
  // async getFuturesOrders() { return this.futuresApi.getFuturesOrders() }
  // async closeFuturesPosition(positionId: string) { return this.futuresApi.closeFuturesPosition(positionId) }

  // ==========================================
  // ADMIN
  // ==========================================

  async getRevenueSummary() { return this.adminApi.getRevenueSummary() }
  async getRevenueRecords(limit?: number, offset?: number) { return this.adminApi.getRevenueRecords(limit, offset) }
  async getVppClusters() { return this.adminApi.getVppClusters() }
  async dispatchVppCluster(clusterId: string, targetKw: number) { return this.adminApi.dispatchVppCluster(clusterId, targetKw) }
  async getAdminStats() { return this.adminApi.getAdminStats() }
  async getSystemHealth() { return this.adminApi.getSystemHealth() }
  async getAdminActivity() { return this.adminApi.getAdminActivity() }
  async getZoneEconomicInsights(timeframe?: string) { return this.adminApi.getZoneEconomicInsights(timeframe) }
  async getGridTopology() { return this.adminApi.getGridTopology() }
  async getAdminUsers(filters?: any) { return this.adminApi.getAdminUsers(filters) }
  async updateUserRole(userId: string, role: string) { return this.adminApi.updateUserRole(userId, role) }
  async deactivateUser(userId: string) { return this.adminApi.deactivateUser(userId) }
  async reactivateUser(userId: string) { return this.adminApi.reactivateUser(userId) }
  async exportTradingHistory(format: 'csv' | 'json', filters?: any) { return this.adminApi.exportTradingHistory(format, filters) }

  // P2P Config Management
  async getP2PConfigs() { return this.adminApi.getP2PConfigs() }
  async updateP2PConfig(key: string, value: number, reason?: string) { return this.adminApi.updateP2PConfig(key, value, reason) }
  async getP2PConfigAudit(key?: string, limit?: number) { return this.adminApi.getP2PConfigAudit(key, limit) }

  // Backward compatibility method for user / admin confusion in  // Analytics / Market Data
  // async getMarketStats() { return this.tradingApi.getMarketStats() }
  // async getMarketAnalytics(params: { timeframe: string }) {
  //   // Old implementation called: `/api/v1/analytics/market?timeframe=${params.timeframe}`
  //   return this.tradingApi.getMarketData() // Close enough to the old implementation which didn't use timeframe anyway
  // }
}

/**
 * Create a new API client instance
 */
export function createApiClient(token?: string): ApiClient {
  return new ApiClient(token)
}

/**
 * Default API client instance (can be used for unauthenticated requests)
 */
export const defaultApiClient = new ApiClient()
