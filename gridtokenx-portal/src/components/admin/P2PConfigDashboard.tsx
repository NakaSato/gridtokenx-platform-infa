'use client'

import React, { useState, useCallback } from 'react'
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import {
    Settings,
    Save,
    RotateCcw,
    TrendingUp,
    DollarSign,
    Zap,
    Activity,
    History,
    AlertCircle,
    CheckCircle2
} from 'lucide-react'
import { useP2PConfig, P2PConfigItem, P2PConfigAuditEntry } from '@/hooks/useApi'
import toast from 'react-hot-toast'

// Use types from useApi.ts
type ConfigItem = P2PConfigItem
type AuditEntry = P2PConfigAuditEntry

function ConfigEditor({
    config,
    onSave,
    isUpdating
}: {
    config: ConfigItem
    onSave: (key: string, value: number, reason?: string) => Promise<void>
    isUpdating: boolean
}) {
    const [value, setValue] = useState(config.config_value.toString())
    const [reason, setReason] = useState('')

    const handleSave = async () => {
        const numValue = parseFloat(value)
        if (isNaN(numValue)) {
            toast.error('Please enter a valid number')
            return
        }
        await onSave(config.config_key, numValue, reason)
        setReason('')
    }

    return (
        <div className="space-y-4 p-4 border rounded-lg bg-card/50">
            <div className="flex items-center justify-between">
                <div>
                    <h4 className="font-medium text-sm">{config.config_key}</h4>
                    {config.description && (
                        <p className="text-xs text-muted-foreground">{config.description}</p>
                    )}
                </div>
                <Badge variant="secondary" className="text-xs">
                    {config.category}
                </Badge>
            </div>

            <div className="grid gap-4">
                <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                        <Label htmlFor={`value-${config.config_key}`}>Value</Label>
                        <Input
                            id={`value-${config.config_key}`}
                            type="number"
                            step="0.01"
                            value={value}
                            onChange={(e) => setValue(e.target.value)}
                            className="font-mono"
                        />
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor={`reason-${config.config_key}`}>
                            Change Reason <span className="text-muted-foreground">(optional)</span>
                        </Label>
                        <Input
                            id={`reason-${config.config_key}`}
                            placeholder="e.g., Grid maintenance cost increase"
                            value={reason}
                            onChange={(e) => setReason(e.target.value)}
                        />
                    </div>
                </div>

                <div className="flex items-center justify-between">
                    <span className="text-xs text-muted-foreground">
                        Last updated: {new Date(config.updated_at).toLocaleString()}
                    </span>
                    <Button
                        size="sm"
                        onClick={handleSave}
                        disabled={isUpdating || parseFloat(value) === config.config_value}
                    >
                        {isUpdating ? (
                            <RotateCcw className="h-4 w-4 mr-2 animate-spin" />
                        ) : (
                            <Save className="h-4 w-4 mr-2" />
                        )}
                        Save
                    </Button>
                </div>
            </div>
        </div>
    )
}

function AuditLog({ entries }: { entries: AuditEntry[] }) {
    if (entries.length === 0) {
        return (
            <div className="text-center py-8 text-muted-foreground">
                <History className="h-8 w-8 mx-auto mb-2 opacity-50" />
                <p>No changes recorded yet</p>
            </div>
        )
    }

    return (
        <div className="space-y-2">
            {entries.map((entry) => (
                <div key={entry.id} className="flex items-center gap-4 p-3 border rounded-lg text-sm">
                    <div className="flex-1">
                        <div className="flex items-center gap-2">
                            <span className="font-medium">{entry.config_key}</span>
                            <span className="text-muted-foreground">changed</span>
                            <span className="font-mono bg-muted px-1.5 py-0.5 rounded">
                                {entry.old_value?.toFixed(4) ?? 'null'}
                            </span>
                            <span className="text-muted-foreground">→</span>
                            <span className="font-mono bg-primary/10 text-primary px-1.5 py-0.5 rounded">
                                {entry.new_value?.toFixed(4) ?? 'null'}
                            </span>
                        </div>
                        {entry.change_reason && (
                            <p className="text-xs text-muted-foreground mt-1">
                                Reason: {entry.change_reason}
                            </p>
                        )}
                    </div>
                    <span className="text-xs text-muted-foreground whitespace-nowrap">
                        {new Date(entry.changed_at).toLocaleString()}
                    </span>
                </div>
            ))}
        </div>
    )
}

export function P2PConfigDashboard() {
    const {
        configs,
        loading,
        error,
        updateConfig,
        updating,
        auditLogs,
        refresh
    } = useP2PConfig()

    const [selectedKey, setSelectedKey] = useState<string | null>(null)

    const handleSave = useCallback(async (key: string, value: number, reason?: string) => {
        const success = await updateConfig(key, value, reason)
        if (success) {
            toast.success(`Updated ${key} successfully`)
        }
    }, [updateConfig])

    // Group configs by category
    const groupedConfigs = (configs || []).reduce<Record<string, ConfigItem[]>>((acc, config) => {
        const category = config.category || 'general'
        if (!acc[category]) {
            acc[category] = []
        }
        acc[category].push(config)
        return acc
    }, {})

    const categories = [
        { id: 'pricing', label: 'Pricing', icon: DollarSign, color: 'text-green-500' },
        { id: 'wheeling', label: 'Wheeling Charges', icon: Zap, color: 'text-yellow-500' },
        { id: 'loss', label: 'Loss Factors', icon: Activity, color: 'text-red-500' },
        { id: 'general', label: 'General', icon: Settings, color: 'text-blue-500' },
    ]

    if (loading) {
        return (
            <div className="flex items-center justify-center h-64">
                <RotateCcw className="h-8 w-8 animate-spin text-muted-foreground" />
            </div>
        )
    }

    if (error) {
        return (
            <Card className="border-red-200 bg-red-50">
                <CardContent className="p-6">
                    <div className="flex items-center gap-2 text-red-600">
                        <AlertCircle className="h-5 w-5" />
                        <span>Error loading configuration: {error}</span>
                    </div>
                </CardContent>
            </Card>
        )
    }

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-2xl font-bold flex items-center gap-2">
                        <Settings className="h-6 w-6" />
                        P2P Market Configuration
                    </h2>
                    <p className="text-muted-foreground">
                        Manage wheeling charges, loss factors, and pricing parameters.
                        Changes take effect immediately without smart contract redeployment.
                    </p>
                </div>
                <Button variant="outline" onClick={refresh}>
                    <RotateCcw className="h-4 w-4 mr-2" />
                    Refresh
                </Button>
            </div>

            {/* Quick Stats */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                {categories.map((cat) => {
                    const count = groupedConfigs[cat.id]?.length ?? 0
                    const Icon = cat.icon
                    return (
                        <Card key={cat.id} className="border-l-4 border-l-primary">
                            <CardContent className="p-4">
                                <div className="flex items-center justify-between">
                                    <Icon className={`h-5 w-5 ${cat.color}`} />
                                    <Badge variant="secondary">{count} settings</Badge>
                                </div>
                                <div className="mt-2">
                                    <div className="text-lg font-semibold">{cat.label}</div>
                                </div>
                            </CardContent>
                        </Card>
                    )
                })}
            </div>

            {/* Main Content */}
            <Tabs defaultValue="pricing" className="w-full">
                <TabsList className="grid w-full grid-cols-4">
                    {categories.map((cat) => (
                        <TabsTrigger key={cat.id} value={cat.id} className="flex items-center gap-2">
                            <cat.icon className="h-4 w-4" />
                            {cat.label}
                        </TabsTrigger>
                    ))}
                </TabsList>

                {categories.map((cat) => (
                    <TabsContent key={cat.id} value={cat.id} className="space-y-4">
                        <Card>
                            <CardHeader>
                                <CardTitle className="flex items-center gap-2">
                                    <cat.icon className={`h-5 w-5 ${cat.color}`} />
                                    {cat.label} Settings
                                </CardTitle>
                                <CardDescription>
                                    {cat.id === 'pricing' && 'Configure base prices, grid import/export rates, and transaction fees.'}
                                    {cat.id === 'wheeling' && 'Set transmission fees for same-zone and cross-zone transactions.'}
                                    {cat.id === 'loss' && 'Define technical loss factors for different zone distances.'}
                                    {cat.id === 'general' && 'General platform configuration parameters.'}
                                </CardDescription>
                            </CardHeader>
                            <CardContent className="space-y-4">
                                {groupedConfigs[cat.id]?.map((config) => (
                                    <ConfigEditor
                                        key={config.config_key}
                                        config={config}
                                        onSave={handleSave}
                                        isUpdating={updating === config.config_key}
                                    />
                                ))}
                                {!groupedConfigs[cat.id]?.length && (
                                    <div className="text-center py-8 text-muted-foreground">
                                        No settings in this category
                                    </div>
                                )}
                            </CardContent>
                        </Card>
                    </TabsContent>
                ))}
            </Tabs>

            {/* Audit Log */}
            <Card>
                <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                        <History className="h-5 w-5" />
                        Recent Changes
                    </CardTitle>
                    <CardDescription>
                        Audit trail of configuration changes
                    </CardDescription>
                </CardHeader>
                <CardContent>
                    <AuditLog entries={auditLogs.slice(0, 10)} />
                </CardContent>
            </Card>
        </div>
    )
}
