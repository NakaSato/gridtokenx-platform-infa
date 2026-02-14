# I-E. Technology Stack & Libraries

<div class="grid grid-cols-2 gap-x-6 gap-y-4">

  <!-- Frontend -->
  <div v-click class="p-4 rounded-xl border border-cyan-500/30 bg-cyan-500/5 hover:border-cyan-500/60 transition-all backdrop-blur-sm group">
    <div class="flex items-center justify-between mb-3">
      <div class="flex items-center gap-3">
        <div class="text-3xl i-ph-desktop-duotone text-cyan-400 group-hover:scale-110 transition-transform"></div>
        <strong class="text-cyan-400 text-lg">Frontend Layer</strong>
      </div>
      <span class="text-[10px] px-2 py-0.5 rounded bg-cyan-500/20 text-cyan-200 border border-cyan-500/30">Client</span>
    </div>
    <div class="space-y-2 text-sm">
      <div class="flex flex-col">
        <span class="text-[10px] opacity-50 uppercase tracking-wider">Core Framework</span>
        <span class="font-mono text-cyan-100/90 text-xs">Next.js 16 (App Router) + React 19</span>
      </div>
      <div class="flex flex-col">
        <span class="text-[10px] opacity-50 uppercase tracking-wider">Styling & UI</span>
        <span class="font-mono text-cyan-100/90 text-xs">Tailwind v4 + Shadcn/UI + Recharts</span>
      </div>
      <div class="flex flex-col">
        <span class="text-[10px] opacity-50 uppercase tracking-wider">Web3 & State</span>
        <span class="font-mono text-cyan-100/90 text-xs">TanStack Query + Wallet Adapter</span>
      </div>
    </div>
  </div>

  <!-- Backend -->
  <div v-click class="p-4 rounded-xl border border-orange-500/30 bg-orange-500/5 hover:border-orange-500/60 transition-all backdrop-blur-sm group">
    <div class="flex items-center justify-between mb-3">
      <div class="flex items-center gap-3">
        <div class="text-3xl i-ph-server-duotone text-orange-400 group-hover:scale-110 transition-transform"></div>
        <strong class="text-orange-400 text-lg">Middleware Layer</strong>
      </div>
      <span class="text-[10px] px-2 py-0.5 rounded bg-orange-500/20 text-orange-200 border border-orange-500/30">Rust</span>
    </div>
    <div class="space-y-2 text-sm">
      <div class="flex flex-col">
        <span class="text-[10px] opacity-50 uppercase tracking-wider">API Gateway</span>
        <span class="font-mono text-orange-100/90 text-xs">Axum 0.8 + Tokio + Tower</span>
      </div>
      <div class="flex flex-col">
        <span class="text-[10px] opacity-50 uppercase tracking-wider">Data & Events</span>
        <span class="font-mono text-orange-100/90 text-xs">Postgres 17 + Redis 7 + Kafka (KRaft)</span>
      </div>
      <div class="flex flex-col">
        <span class="text-[10px] opacity-50 uppercase tracking-wider">Ops & Auth</span>
        <span class="font-mono text-orange-100/90 text-xs">JWT + OpenAPI (Utoipa) + Prometheus</span>
      </div>
    </div>
  </div>

  <!-- Blockchain -->
  <div v-click class="p-4 rounded-xl border border-purple-500/30 bg-purple-500/5 hover:border-purple-500/60 transition-all backdrop-blur-sm group">
    <div class="flex items-center justify-between mb-3">
      <div class="flex items-center gap-3">
        <div class="text-3xl i-ph-cube-duotone text-purple-400 group-hover:scale-110 transition-transform"></div>
        <strong class="text-purple-400 text-lg">Consensus Layer</strong>
      </div>
      <span class="text-[10px] px-2 py-0.5 rounded bg-purple-500/20 text-purple-200 border border-purple-500/30">Solana</span>
    </div>
    <div class="space-y-2 text-sm">
      <div class="flex flex-col">
        <span class="text-[10px] opacity-50 uppercase tracking-wider">Smart Contracts</span>
        <span class="font-mono text-purple-100/90 text-xs">Anchor 0.30+ (Sealevel BPF)</span>
      </div>
      <div class="flex flex-col">
        <span class="text-[10px] opacity-50 uppercase tracking-wider">Token Standard</span>
        <span class="font-mono text-purple-100/90 text-xs">SPL Token-2022 + Metadata</span>
      </div>
      <div class="flex flex-col">
        <span class="text-[10px] opacity-50 uppercase tracking-wider">Security</span>
        <span class="font-mono text-purple-100/90 text-xs">Ed25519 + PDA Seeds + CPI Guard</span>
      </div>
    </div>
  </div>

  <!-- Simulator -->
  <div v-click class="p-4 rounded-xl border border-yellow-500/30 bg-yellow-500/5 hover:border-yellow-500/60 transition-all backdrop-blur-sm group">
    <div class="flex items-center justify-between mb-3">
      <div class="flex items-center gap-3">
        <div class="text-3xl i-ph-cpu-duotone text-yellow-400 group-hover:scale-110 transition-transform"></div>
        <strong class="text-yellow-400 text-lg">Edge/IoT Layer</strong>
      </div>
      <span class="text-[10px] px-2 py-0.5 rounded bg-yellow-500/20 text-yellow-200 border border-yellow-500/30">Python</span>
    </div>
    <div class="space-y-2 text-sm">
      <div class="flex flex-col">
        <span class="text-[10px] opacity-50 uppercase tracking-wider">Core Logic</span>
        <span class="font-mono text-yellow-100/90 text-xs">FastAPI + Asyncio + Pydantic v2</span>
      </div>
      <div class="flex flex-col">
        <span class="text-[10px] opacity-50 uppercase tracking-wider">Data Analytics</span>
        <span class="font-mono text-yellow-100/90 text-xs">Pandas 2.2 + NumPy + Matplotlib</span>
      </div>
      <div class="flex flex-col">
        <span class="text-[10px] opacity-50 uppercase tracking-wider">Telemetry</span>
        <span class="font-mono text-yellow-100/90 text-xs">InfluxDB + WebSocket Stream</span>
      </div>
    </div>
  </div>

</div>
