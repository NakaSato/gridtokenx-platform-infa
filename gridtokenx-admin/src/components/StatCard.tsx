interface StatCardProps {
    title: string;
    value: string;
    change?: string;
    changeType?: 'positive' | 'negative' | 'neutral';
    icon: React.ReactNode;
    subtitle?: string;
}

export default function StatCard({
    title,
    value,
    change,
    changeType = 'neutral',
    icon,
    subtitle,
}: StatCardProps) {
    const changeColors = {
        positive: 'text-[var(--success)]',
        negative: 'text-[var(--danger)]',
        neutral: 'text-[var(--muted)]',
    };

    return (
        <div className="stat-card animate-fadeIn">
            <div className="flex items-start justify-between">
                <div>
                    <p className="text-sm text-[var(--muted)] font-medium">{title}</p>
                    <p className="text-3xl font-bold mt-2">{value}</p>
                    {subtitle && (
                        <p className="text-xs text-[var(--muted)] mt-1">{subtitle}</p>
                    )}
                    {change && (
                        <div className={`flex items-center gap-1 mt-2 text-sm ${changeColors[changeType]}`}>
                            {changeType === 'positive' && (
                                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 10l7-7m0 0l7 7m-7-7v18" />
                                </svg>
                            )}
                            {changeType === 'negative' && (
                                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 14l-7 7m0 0l-7-7m7 7V3" />
                                </svg>
                            )}
                            <span>{change}</span>
                        </div>
                    )}
                </div>
                <div className="w-12 h-12 rounded-xl bg-[var(--primary)]/20 flex items-center justify-center text-[var(--primary)]">
                    {icon}
                </div>
            </div>
        </div>
    );
}
