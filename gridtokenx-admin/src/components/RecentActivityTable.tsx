export interface Transaction {
    id: string;
    user: string;
    type: string;
    amount: string;
    status: string;
    time: string;
}

interface RecentActivityTableProps {
    transactions: Transaction[];
}

export default function RecentActivityTable({ transactions }: RecentActivityTableProps) {
    const statusColors: Record<string, string> = {
        completed: 'badge-success',
        pending: 'badge-warning',
        processing: 'badge-info',
        failed: 'badge-danger',
    };

    return (
        <div className="card">
            <div className="flex items-center justify-between mb-6">
                <div>
                    <h3 className="text-lg font-semibold">Recent Activity</h3>
                    <p className="text-sm text-[var(--muted)]">Latest transactions and events</p>
                </div>
                <button className="btn-secondary text-sm">View All</button>
            </div>

            <div className="overflow-x-auto">
                <table className="table">
                    <thead>
                        <tr>
                            <th>Transaction ID</th>
                            <th>User</th>
                            <th>Type</th>
                            <th>Amount</th>
                            <th>Status</th>
                            <th>Time</th>
                        </tr>
                    </thead>
                    <tbody>
                        {transactions.length === 0 ? (
                            <tr>
                                <td colSpan={6} className="text-center py-4 text-[var(--muted)]">
                                    No recent activity found.
                                </td>
                            </tr>
                        ) : (
                            transactions.map((tx) => (
                                <tr key={tx.id}>
                                    <td className="font-mono text-sm">{tx.id}</td>
                                    <td className="font-mono text-sm text-[var(--muted)]">{tx.user}</td>
                                    <td>{tx.type}</td>
                                    <td className="font-medium">{tx.amount}</td>
                                    <td>
                                        <span className={`badge ${statusColors[tx.status] || 'badge-info'}`}>
                                            {tx.status}
                                        </span>
                                    </td>
                                    <td className="text-[var(--muted)]">{tx.time}</td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    );
}
