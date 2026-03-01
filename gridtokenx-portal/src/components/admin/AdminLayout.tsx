'use client'

import React from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import {
    LayoutDashboard,
    Users,
    DollarSign,
    Zap,
    Activity,
    BarChart3,
    Shield,
    ChevronRight,
    Home,
    Menu,
    X
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { cn } from '@/lib/utils'

interface AdminLayoutProps {
    children: React.ReactNode
    title?: string
    description?: string
    action?: React.ReactNode
}

const navItems = [
    { href: '/admin', label: 'Dashboard', icon: LayoutDashboard },
    { href: '/admin/analytics', label: 'Analytics', icon: BarChart3 },
    { href: '/admin/users', label: 'Users', icon: Users },
    { href: '/admin/revenue', label: 'Revenue', icon: DollarSign },
    { href: '/admin/vpp', label: 'VPP', icon: Zap },
    { href: '/admin/health', label: 'Health', icon: Activity },
    { href: '/admin/activity', label: 'Activity Log', icon: Shield },
]

function Breadcrumbs() {
    const pathname = usePathname()
    const segments = pathname.split('/').filter(Boolean)

    if (segments.length <= 1) return null

    return (
        <nav className="flex items-center gap-2 text-sm text-muted-foreground mb-4">
            <Link href="/admin" className="hover:text-primary transition-colors flex items-center gap-1">
                <Home className="h-3.5 w-3.5" />
                Admin
            </Link>
            {segments.slice(1).map((segment, index) => {
                const href = '/' + segments.slice(0, index + 2).join('/')
                const isLast = index === segments.slice(1).length - 1
                const label = segment.charAt(0).toUpperCase() + segment.slice(1).replace(/-/g, ' ')

                return (
                    <React.Fragment key={href}>
                        <ChevronRight className="h-3.5 w-3.5" />
                        {isLast ? (
                            <span className="text-foreground font-medium">{label}</span>
                        ) : (
                            <Link href={href} className="hover:text-primary transition-colors">
                                {label}
                            </Link>
                        )}
                    </React.Fragment>
                )
            })}
        </nav>
    )
}

export function AdminLayout({ children, title, description, action }: AdminLayoutProps) {
    const pathname = usePathname()
    const [mobileMenuOpen, setMobileMenuOpen] = React.useState(false)

    return (
        <div className="min-h-screen bg-background flex">
            {/* Sidebar - Desktop */}
            <aside className="hidden lg:flex w-64 flex-col border-r bg-card/50 backdrop-blur-sm fixed h-full">
                <div className="p-6 border-b">
                    <Link href="/admin" className="flex items-center gap-3">
                        <div className="p-2 bg-primary/10 rounded-lg">
                            <Shield className="h-5 w-5 text-primary" />
                        </div>
                        <div>
                            <h2 className="font-bold text-lg">Admin Portal</h2>
                            <p className="text-[10px] text-muted-foreground uppercase tracking-wider">Command Center</p>
                        </div>
                    </Link>
                </div>

                <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
                    {navItems.map((item) => {
                        const isActive = pathname === item.href || pathname.startsWith(item.href + '/')
                        const Icon = item.icon

                        return (
                            <Link
                                key={item.href}
                                href={item.href}
                                className={cn(
                                    "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all",
                                    isActive
                                        ? "bg-primary/10 text-primary border-l-2 border-primary"
                                        : "text-muted-foreground hover:text-foreground hover:bg-muted"
                                )}
                            >
                                <Icon className={cn("h-4 w-4", isActive && "text-primary")} />
                                {item.label}
                                {isActive && (
                                    <div className="ml-auto w-1.5 h-1.5 rounded-full bg-primary" />
                                )}
                            </Link>
                        )
                    })}
                </nav>

                <div className="p-4 border-t">
                    <div className="bg-muted/50 rounded-lg p-3">
                        <div className="flex items-center gap-2 mb-2">
                            <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
                            <span className="text-xs font-medium">System Operational</span>
                        </div>
                        <p className="text-[10px] text-muted-foreground">All services running normally</p>
                    </div>
                </div>
            </aside>

            {/* Mobile Header */}
            <div className="lg:hidden fixed top-0 left-0 right-0 z-50 bg-background/80 backdrop-blur-md border-b">
                <div className="flex items-center justify-between p-4">
                    <Link href="/admin" className="flex items-center gap-2">
                        <Shield className="h-5 w-5 text-primary" />
                        <span className="font-bold">Admin Portal</span>
                    </Link>
                    <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                    >
                        {mobileMenuOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
                    </Button>
                </div>

                {/* Mobile Menu */}
                {mobileMenuOpen && (
                    <nav className="border-t bg-card p-4 space-y-1">
                        {navItems.map((item) => {
                            const isActive = pathname === item.href
                            const Icon = item.icon

                            return (
                                <Link
                                    key={item.href}
                                    href={item.href}
                                    onClick={() => setMobileMenuOpen(false)}
                                    className={cn(
                                        "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all",
                                        isActive
                                            ? "bg-primary/10 text-primary"
                                            : "text-muted-foreground hover:text-foreground hover:bg-muted"
                                    )}
                                >
                                    <Icon className="h-4 w-4" />
                                    {item.label}
                                </Link>
                            )
                        })}
                    </nav>
                )}
            </div>

            {/* Main Content */}
            <main className="flex-1 lg:ml-64 pt-16 lg:pt-0">
                <div className="p-4 lg:p-8 max-w-7xl mx-auto">
                    {/* Breadcrumbs */}
                    <Breadcrumbs />

                    {/* Page Header */}
                    {(title || description) && (
                        <header className="mb-8">
                            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                                <div>
                                    {title && <h1 className="text-3xl font-bold tracking-tight">{title}</h1>}
                                    {description && <p className="text-muted-foreground mt-1">{description}</p>}
                                </div>
                                {action && <div>{action}</div>}
                            </div>
                        </header>
                    )}

                    {children}
                </div>
            </main>
        </div>
    )
}
