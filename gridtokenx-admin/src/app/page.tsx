'use client';

import { useState, useEffect } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { StatCard, RevenueChart, PlatformHealthCard, RecentActivityTable } from '@/components';
import { Skeleton } from '@/components/ui/skeleton';
import { defaultApiClient, AdminStatsResponse, AuditEventRecord, DetailedHealthStatus } from '@/lib/api-client';

interface DashboardStats {
  total_revenue: number;
  active_users: number;
  total_orders: number;
  energy_traded: number;
  revenue_change: string;
  users_change: string;
  orders_change: string;
  energy_change: string;
}

// Interfaces aligned with components
interface Transaction {
  id: string;
  user: string;
  type: string;
  amount: string;
  status: string;
  time: string;
}

interface PlatformHealth {
  api_gateway: string;
  blockchain_rpc: string;
  order_matching: string;
  settlement_queue: number;
}

export default function Dashboard() {
  const queryClient = useQueryClient();

  // Admin Token State
  const [adminToken, setAdminToken] = useState<string>('');
  const [showTokenInput, setShowTokenInput] = useState(false);

  useEffect(() => {
    // Load token from localStorage if available
    const savedToken = localStorage.getItem('admin_token');
    if (savedToken) {
      setAdminToken(savedToken);
      defaultApiClient.setToken(savedToken);
    }
  }, []);

  const handleTokenSave = () => {
    localStorage.setItem('admin_token', adminToken);
    defaultApiClient.setToken(adminToken);
    setShowTokenInput(false);
    // Invalidate all queries to force refetch with new token
    queryClient.invalidateQueries();
  };

  // Queries
  const { data: statsData, isLoading: statsLoading } = useQuery({
    queryKey: ['admin-stats'],
    queryFn: async () => {
      const res = await defaultApiClient.getAdminStats();
      return res.data;
    }
  });

  const { data: activityData, isLoading: activityLoading } = useQuery({
    queryKey: ['admin-activity'],
    queryFn: async () => {
      const res = await defaultApiClient.getRecentActivity();
      return res.data || [];
    }
  });

  const { data: healthData, isLoading: healthLoading } = useQuery({
    queryKey: ['admin-health'],
    queryFn: async () => {
      const res = await defaultApiClient.getSystemHealth();
      return res.data;
    },
    refetchInterval: 30000 // Refetch health every 30s
  });

  const loading = statsLoading || activityLoading || healthLoading;

  // Transform Data
  const stats: DashboardStats = {
    total_revenue: statsData?.total_revenue || 0,
    active_users: statsData?.total_users || 0,
    total_orders: statsData?.total_orders || 0,
    energy_traded: statsData?.total_volume_kwh || 0,
    revenue_change: '+0%', // Placeholder from legacy code
    users_change: '+0',
    orders_change: '+0%',
    energy_change: '+0%',
  };

  const transactions: Transaction[] = (activityData || [])
    .slice(0, 5)
    .map((log: AuditEventRecord) => ({
      id: log.id.substring(0, 8),
      user: log.user_id ? log.user_id.substring(0, 8) : 'System',
      type: log.action,
      amount: '-', // Details in metadata usually
      status: log.status,
      time: new Date(log.created_at).toLocaleTimeString(),
    }));

  const health: PlatformHealth = {
    api_gateway: healthData?.checks.database || 'offline',
    blockchain_rpc: healthData?.checks.blockchain || 'offline',
    order_matching: 'running', // Assume running if API is up
    settlement_queue: healthData?.system.active_requests || 0,
  };

  if (loading && !statsData) {
    return (
      <div className="space-y-6 animate-fadeIn">
        <div>
          <h1 className="text-2xl font-bold">Dashboard</h1>
          <p className="text-[var(--muted)]">Loading...</p>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="card">
              <Skeleton className="h-4 w-24 mb-2" />
              <Skeleton className="h-8 w-32 mb-2" />
              <Skeleton className="h-3 w-20" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fadeIn">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Dashboard</h1>
          <p className="text-[var(--muted)]">Welcome back! Here&apos;s what&apos;s happening on GridTokenX.</p>
        </div>
        <div className="flex items-center gap-3">
          {/* Token Input for Admin Auth */}
          <div className="relative">
            {showTokenInput ? (
              <div className="flex items-center gap-2 bg-background border p-1 rounded-md absolute right-0 top-0 mt-10 z-50 shadow-lg min-w-[300px]">
                <input
                  type="text"
                  value={adminToken}
                  onChange={(e) => setAdminToken(e.target.value)}
                  placeholder="Enter Admin Bearer Token"
                  className="text-xs p-2 border rounded w-full"
                />
                <button onClick={handleTokenSave} className="bg-primary text-primary-foreground text-xs px-2 py-1 rounded">Save</button>
              </div>
            ) : null}
            <button
              onClick={() => setShowTokenInput(!showTokenInput)}
              className={`text-xs px-3 py-2 rounded-md border ${adminToken ? 'bg-green-500/10 border-green-500 text-green-500' : 'bg-secondary text-secondary-foreground'}`}
            >
              {adminToken ? '🔑 Admin Connected' : '🔑 Set Token'}
            </button>
          </div>

          <button onClick={() => queryClient.invalidateQueries()} className="btn-secondary flex items-center gap-2">
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
            Refresh
          </button>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
        <StatCard
          title="Total Revenue"
          value={`฿${stats.total_revenue.toLocaleString()}`}
          change={`${stats.revenue_change} from last month`}
          changeType="positive"
          subtitle="Platform fees + charges"
          icon={
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          }
        />
        <StatCard
          title="Active Users"
          value={stats.active_users.toLocaleString()}
          change={`${stats.users_change} new this week`}
          changeType="positive"
          subtitle="Registered accounts"
          icon={
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
            </svg>
          }
        />
        <StatCard
          title="Total Orders"
          value={stats.total_orders.toLocaleString()}
          change={`${stats.orders_change} from yesterday`}
          changeType="positive"
          subtitle="Buy & Sell orders"
          icon={
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
            </svg>
          }
        />
        <StatCard
          title="Energy Traded"
          value={`${stats.energy_traded} MWh`}
          change={`${stats.energy_change} from last week`}
          changeType={stats.energy_change.startsWith('-') ? 'negative' : 'positive'}
          subtitle="Total volume"
          icon={
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
            </svg>
          }
        />
      </div>

      {/* Charts and Activity Row */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        {/* Revenue Chart - Takes 2 columns */}
        <div className="xl:col-span-2">
          <RevenueChart />
        </div>

        {/* Quick Stats */}
        <PlatformHealthCard health={health} />
      </div>

      {/* Recent Activity Table */}
      <RecentActivityTable transactions={transactions} />
    </div>
  );
}
