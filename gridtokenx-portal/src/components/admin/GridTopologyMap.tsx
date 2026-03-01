'use client'

import React, { useMemo } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  useGridTopology,
  useAuth
} from '@/hooks/useApi'
import { GridTopologyResponse } from '@/types/grid'
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from '@/components/ui/card'
import {
  Activity,
  Zap,
  AlertTriangle,
  Info,
  RefreshCw,
  Maximize2
} from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Skeleton } from '@/components/ui/skeleton'

/**
 * GridTopologyMap Component
 * Visualizes the physical distribution network as a topology of zones and branches.
 */
export function GridTopologyMap() {
  const { token } = useAuth()
  const { topology, loading, error, refetch } = useGridTopology(token ?? undefined)

  const topoData = topology as unknown as GridTopologyResponse

  const branches = topoData?.branches || []
  const zones = topoData?.zones || {}

  // Calculate bounding box for normalization
  const bounds = useMemo(() => {
    const zoneList = Object.values(zones)
    if (zoneList.length === 0) return { minLat: 0, maxLat: 1, minLon: 0, maxLon: 1 }

    return {
      minLat: Math.min(...zoneList.map(z => z.centroid_lat)),
      maxLat: Math.max(...zoneList.map(z => z.centroid_lat)),
      minLon: Math.min(...zoneList.map(z => z.centroid_lon)),
      maxLon: Math.max(...zoneList.map(z => z.centroid_lon)),
    }
  }, [zones])

  // Scale coordinates to fit SVG viewbox (800x600)
  const project = (lat: number, lon: number) => {
    const padding = 100
    const width = 800 - padding * 2
    const height = 600 - padding * 2

    const latRange = bounds.maxLat - bounds.minLat || 1
    const lonRange = bounds.maxLon - bounds.minLon || 1

    const x = padding + ((lon - bounds.minLon) / lonRange) * width
    const y = padding + (height - ((lat - bounds.minLat) / latRange) * height) // Flip Y for SVG

    return { x, y }
  }

  if (loading && !topology) {
    return (
      <Card className="border-none shadow-lg bg-card/60 backdrop-blur-sm overflow-hidden">
        <CardHeader className="border-b border-white/5 pb-2">
          <Skeleton className="h-6 w-48 mb-2" />
          <Skeleton className="h-4 w-64" />
        </CardHeader>
        <CardContent className="h-[500px] flex items-center justify-center">
          <RefreshCw className="h-10 w-10 animate-spin text-primary opacity-20" />
        </CardContent>
      </Card>
    )
  }

  if (error) {
    return (
      <Card className="border-none shadow-lg bg-card/60 backdrop-blur-sm">
        <CardContent className="h-96 flex flex-col items-center justify-center text-center p-6">
          <AlertTriangle className="h-12 w-12 text-destructive mb-4" />
          <h3 className="text-xl font-bold mb-2">Topology Sink Failure</h3>
          <p className="text-muted-foreground">{error}</p>
          <button
            onClick={() => refetch()}
            className="mt-6 px-4 py-2 bg-primary text-white rounded-lg flex items-center gap-2 hover:bg-primary/80 transition-all"
          >
            <RefreshCw className="h-4 w-4" />
            Re-initialize
          </button>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card className="border-none shadow-lg bg-card/60 backdrop-blur-sm overflow-hidden group">
      <CardHeader className="border-b border-white/5 flex flex-row items-center justify-between space-y-0">
        <div>
          <CardTitle className="text-xl font-bold flex items-center gap-2">
            <Zap className="h-5 w-5 text-yellow-500" />
            Live Grid Topology
          </CardTitle>
          <CardDescription>Real-time transmission flow and capacity utilization heatmap.</CardDescription>
        </div>
        <div className="flex gap-2">
          <Badge variant="outline" className="bg-green-500/10 text-green-500 border-none">
            Healthy
          </Badge>
          <button className="p-2 hover:bg-white/5 rounded-full transition-colors">
            <Maximize2 className="h-4 w-4" />
          </button>
        </div>
      </CardHeader>
      <CardContent className="p-0 relative bg-black/20">
        <svg viewBox="0 0 800 600" className="w-full h-full max-h-[600px] min-h-[400px]">
          {/* Definitions for Glow effects */}
          <defs>
            <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
              <feGaussianBlur stdDeviation="3" result="blur" />
              <feComposite in="SourceGraphic" in2="blur" operator="over" />
            </filter>
          </defs>

          {/* Branches (Transmission Lines) */}
          {branches.map((branch, i) => {
            const from = zones[branch.from_zone]
            const to = zones[branch.to_zone]
            if (!from || !to) return null

            const p1 = project(from.centroid_lat, from.centroid_lon)
            const p2 = project(to.centroid_lat, to.centroid_lon)

            const usage = branch.capacity_kwh > 0
              ? (branch.current_flow_kwh / branch.capacity_kwh) * 100
              : 0

            // Heatmap coloring: Green -> Yellow -> Orange -> Red
            const color = usage > 90 ? '#ef4444' : usage > 70 ? '#f97316' : usage > 40 ? '#eab308' : '#3b82f6'
            const thickness = usage > 90 ? 4 : usage > 50 ? 3 : 2

            return (
              <React.Fragment key={`branch-${i}`}>
                {/* Shadow/Glow line */}
                <motion.line
                  x1={p1.x} y1={p1.y}
                  x2={p2.x} y2={p2.y}
                  stroke={color}
                  strokeWidth={thickness + 4}
                  strokeOpacity={0.1}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                />
                {/* Main line */}
                <motion.line
                  x1={p1.x} y1={p1.y}
                  x2={p2.x} y2={p2.y}
                  stroke={color}
                  strokeWidth={thickness}
                  strokeOpacity={0.6}
                  strokeLinecap="round"
                  initial={{ pathLength: 0 }}
                  animate={{ pathLength: 1 }}
                  transition={{ duration: 1.5, ease: "easeOut" }}
                />
                {/* Flow Animation Particle */}
                {branch.current_flow_kwh > 0 && (
                  <motion.circle
                    r={2}
                    fill={color}
                    filter="url(#glow)"
                    animate={{
                      cx: [p1.x, p2.x],
                      cy: [p1.y, p2.y]
                    }}
                    transition={{
                      duration: Math.max(0.5, 3 - (usage / 50)),
                      repeat: Infinity,
                      ease: "linear"
                    }}
                  />
                )}
              </React.Fragment>
            )
          })}

          {/* Zones (Nodes) */}
          {Object.values(zones).map((zone) => {
            const p = project(zone.centroid_lat, zone.centroid_lon)

            return (
              <motion.g
                key={`zone-${zone.zone_id}`}
                className="cursor-pointer"
                whileHover={{ scale: 1.1 }}
              >
                <motion.circle
                  cx={p.x}
                  cy={p.y}
                  r={12}
                  fill="#171717"
                  stroke="#3b82f6"
                  strokeWidth={2}
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ type: "spring", damping: 10, stiffness: 100 }}
                />
                <motion.circle
                  cx={p.x}
                  cy={p.y}
                  r={4}
                  fill="#3b82f6"
                />
                <text
                  x={p.x}
                  y={p.y + 25}
                  textAnchor="middle"
                  className="text-[10px] fill-muted-foreground font-medium uppercase tracking-wider"
                >
                  Zone {zone.zone_id}
                </text>
                <text
                  x={p.x}
                  y={p.y - 18}
                  textAnchor="middle"
                  className="text-[8px] fill-white/40 font-mono"
                >
                  {zone.meter_count} MT
                </text>
              </motion.g>
            )
          })}
        </svg>

        {/* Legend Overlay */}
        <div className="absolute bottom-6 left-6 p-4 bg-black/40 backdrop-blur-md rounded-xl border border-white/5 space-y-2 pointer-events-none">
          <p className="text-[10px] font-bold uppercase tracking-widest text-primary mb-2">Congestion Metrics</p>
          <div className="flex items-center gap-2 text-xs">
            <div className="h-2 w-2 rounded-full bg-[#3b82f6]" />
            <span className="text-white/60">Optimized (&lt;40%)</span>
          </div>
          <div className="flex items-center gap-2 text-xs">
            <div className="h-2 w-2 rounded-full bg-[#eab308]" />
            <span className="text-white/60">Moderate (40-70%)</span>
          </div>
          <div className="flex items-center gap-2 text-xs">
            <div className="h-2 w-2 rounded-full bg-[#f97316]" />
            <span className="text-white/60">High Congestion (70%+)</span>
          </div>
          <div className="flex items-center gap-2 text-xs">
            <div className="h-2 w-2 rounded-full bg-[#ef4444] animate-pulse" />
            <span className="text-white/60 font-bold">Structural Limit!</span>
          </div>
        </div>

        {/* Info Panel Overlay */}
        <div className="absolute top-6 right-6 p-4 bg-black/40 backdrop-blur-md rounded-xl border border-white/5 space-y-1 w-48 hidden lg:block">
          <div className="flex items-center gap-2 mb-2">
            <Activity className="h-4 w-4 text-green-500" />
            <span className="text-xs font-bold uppercase tracking-widest">Network Health</span>
          </div>
          <div className="space-y-2">
            <div>
              <p className="text-[10px] text-white/40 uppercase">Total Capacity</p>
              <p className="text-sm font-mono">1.25 GWh</p>
            </div>
            <div>
              <p className="text-[10px] text-white/40 uppercase">Efficiency Factor</p>
              <p className="text-sm font-mono text-green-500">98.4%</p>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
