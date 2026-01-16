import { DetailedHealthStatus } from '@/lib/api-client';

interface PlatformHealth {
    api_gateway: string;
    blockchain_rpc: string;
    order_matching: string;
    settlement_queue: number;
}

interface PlatformHealthCardProps {
    health: PlatformHealth;
}

export default function PlatformHealthCard({ health }: PlatformHealthCardProps) {
    const healthColors: Record<string, string> = {
        online: 'bg-[var(--success)]',
        running: 'bg-[var(--success)]',
        offline: 'bg-[var(--danger)]',
        warning: 'bg-[var(--warning)]',
    };

    return (
        <div className="card">
            <h3 className="text-lg font-semibold mb-4">Platform Health</h3>
            <div className="space-y-4">
                <div className="flex items-center justify-between p-3 rounded-lg bg-[var(--card-hover)]">
                    <div className="flex items-center gap-3">
                        <div className={`w-3 h-3 rounded-full ${healthColors[health.api_gateway] || 'bg-gray-400'} animate-pulse`}></div>
                        <span>API Gateway</span>
                    </div>
                    <span className="badge badge-success">{health.api_gateway === 'online' ? 'Online' : health.api_gateway}</span>
                </div>
                <div className="flex items-center justify-between p-3 rounded-lg bg-[var(--card-hover)]">
                    <div className="flex items-center gap-3">
                        <div className={`w-3 h-3 rounded-full ${healthColors[health.blockchain_rpc] || 'bg-gray-400'} animate-pulse`}></div>
                        <span>Blockchain RPC</span>
                    </div>
                    <span className="badge badge-success">{health.blockchain_rpc === 'online' ? 'Online' : health.blockchain_rpc}</span>
                </div>
                <div className="flex items-center justify-between p-3 rounded-lg bg-[var(--card-hover)]">
                    <div className="flex items-center gap-3">
                        <div className={`w-3 h-3 rounded-full ${healthColors[health.order_matching] || 'bg-gray-400'} animate-pulse`}></div>
                        <span>Order Matching</span>
                    </div>
                    <span className="badge badge-success">{health.order_matching === 'running' ? 'Running' : health.order_matching}</span>
                </div>
                <div className="flex items-center justify-between p-3 rounded-lg bg-[var(--card-hover)]">
                    <div className="flex items-center gap-3">
                        <div className={`w-3 h-3 rounded-full ${health.settlement_queue > 0 ? 'bg-[var(--warning)]' : 'bg-[var(--success)]'}`}></div>
                        <span>Settlement Queue</span>
                    </div>
                    <span className={`badge ${health.settlement_queue > 0 ? 'badge-warning' : 'badge-success'}`}>
                        {health.settlement_queue} pending
                    </span>
                </div>
            </div>
        </div>
    );
}
