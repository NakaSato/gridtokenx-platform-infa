# I-C. Frontend Architecture

<div class="grid grid-cols-2 gap-8 mt-6">
  <div class="flex flex-col gap-2 text-sm">
    <div v-click class="p-3 rounded-lg border border-cyan-500/40 bg-cyan-500/10 hover:bg-cyan-500/15 transition-all">
      <strong class="text-cyan-400 text-sm">Next.js 16 App Router</strong><br>
      <span class="text-xs opacity-80 mt-1 block">React Server Components • Streaming SSR • Route handlers • Middleware</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-purple-500/40 bg-purple-500/10 hover:bg-purple-500/15 transition-all">
      <strong class="text-purple-400 text-sm">Wallet Integration</strong><br>
      <span class="text-xs opacity-80 mt-1 block">Multi-wallet adapter • Phantom/Solflare • Transaction signing • Auto-retry</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-green-500/40 bg-green-500/10 hover:bg-green-500/15 transition-all">
      <strong class="text-green-400 text-sm">Real-time Updates</strong><br>
      <span class="text-xs opacity-80 mt-1 block">WebSocket subscriptions • Order book streaming • Price feed • Heartbeat</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-orange-500/40 bg-orange-500/10 hover:bg-orange-500/15 transition-all">
      <strong class="text-orange-400 text-sm">UI Components</strong><br>
      <span class="text-xs opacity-80 mt-1 block">Tailwind CSS • shadcn/ui • Chart.js • Responsive design</span>
    </div>
  </div>
  <div class="flex justify-center items-center">
    <img src="/architecture/architecture_frontend.svg" class="max-h-[440px] object-contain shadow-2xl rounded-lg" />
  </div>
</div>

---

# I-D. Data & Simulator Layer

<div class="grid grid-cols-2 gap-8">
  <div class="flex flex-col gap-2 text-sm">
    <div v-click class="p-3 rounded-lg border border-yellow-500/40 bg-yellow-500/10 hover:bg-yellow-500/15 transition-all">
      <strong class="text-yellow-400 text-sm">Smart Meter Simulator</strong><br>
      <span class="text-xs opacity-80 mt-1 block">FastAPI async • 10K concurrent meters • Solar curves • Ed25519 signing</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-purple-500/40 bg-purple-500/10 hover:bg-purple-500/15 transition-all">
      <strong class="text-purple-400 text-sm">Kafka Event Streaming</strong><br>
      <span class="text-xs opacity-80 mt-1 block">25K msg/s • 3 partitions • Snappy compression • Exactly-once delivery</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-orange-500/40 bg-orange-500/10 hover:bg-orange-500/15 transition-all">
      <strong class="text-orange-400 text-sm">InfluxDB Time-Series</strong><br>
      <span class="text-xs opacity-80 mt-1 block">TSM engine • 1-min aggregations • 30-day retention • Continuous queries</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-blue-500/40 bg-blue-500/10 hover:bg-blue-500/15 transition-all">
      <strong class="text-blue-400 text-sm">Config Storage</strong><br>
      <span class="text-xs opacity-80 mt-1 block">PostgreSQL JSONB • Meter metadata • GIN indexes • HA replication</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-green-500/40 bg-green-500/10 hover:bg-green-500/15 transition-all">
      <strong class="text-green-400 text-sm">Rust Data Pipeline</strong><br>
      <span class="text-xs opacity-80 mt-1 block">rdkafka consumer • Zero-copy deserialize • Batching • Back-pressure</span>
    </div>
  </div>
  <div class="flex justify-center items-center">
    <img src="/architecture/architecture_simulator.svg" class="max-h-[440px] object-contain shadow-2xl rounded-lg" />
  </div>
</div>
