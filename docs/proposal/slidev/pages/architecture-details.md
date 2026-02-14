# I-A. Backend Architecture

<div class="grid grid-cols-2 gap-8 mt-6">
  <div class="flex flex-col gap-2 text-sm">
    <div v-click class="p-3 rounded-lg border border-orange-500/40 bg-orange-500/10 hover:bg-orange-500/15 transition-all">
      <strong class="text-orange-400 text-sm">API Gateway (Rust/Axum)</strong><br>
      <span class="text-xs opacity-80 mt-1 block">Async runtime with 15K req/s throughput • Connection pooling • Circuit breakers</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-blue-500/40 bg-blue-500/10 hover:bg-blue-500/15 transition-all">
      <strong class="text-blue-400 text-sm">PostgreSQL 17</strong><br>
      <span class="text-xs opacity-80 mt-1 block">JSONB indexing • Logical replication • Partitioning for 1M+ records</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-red-500/40 bg-red-500/10 hover:bg-red-500/15 transition-all">
      <strong class="text-red-400 text-sm">Redis 7 Cluster</strong><br>
      <span class="text-xs opacity-80 mt-1 block">Sub-ms latency • Pipelining • Session store with 10K active users</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-purple-500/40 bg-purple-500/10 hover:bg-purple-500/15 transition-all">
      <strong class="text-purple-400 text-sm">Kafka 3.x (KRaft)</strong><br>
      <span class="text-xs opacity-80 mt-1 block">25K msg/s peak • meter-readings topic • Snappy compression</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-green-500/40 bg-green-500/10 hover:bg-green-500/15 transition-all">
      <strong class="text-green-400 text-sm">Solana RPC</strong><br>
      <span class="text-xs opacity-80 mt-1 block">WebSocket subscriptions • Transaction batching • 400ms block time</span>
    </div>
  </div>
  <div class="flex justify-center items-center">
    <img src="/architecture/architecture_backend.svg" class="max-h-[440px] object-contain shadow-2xl rounded-lg" />
  </div>
</div>

---

# I-B. Blockchain Architecture

<div class="grid grid-cols-2 gap-8 mt-6">
  <div class="flex flex-col gap-2 text-sm">
    <div v-click class="p-3 rounded-lg border border-[#14f195]/40 bg-[#14f195]/10 hover:bg-[#14f195]/15 transition-all">
      <strong class="text-[#14f195] text-sm">Solana PoA Cluster</strong><br>
      <span class="text-xs opacity-80 mt-1 block">3 authorized validators • 400ms block time • 850 TPS capacity • Sub-second finality</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-purple-500/40 bg-purple-500/10 hover:bg-purple-500/15 transition-all">
      <strong class="text-purple-400 text-sm">Registry Program</strong><br>
      <span class="text-xs opacity-80 mt-1 block">PDA derivation for 10K+ meters • State validation • Ed25519 attestation</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-blue-500/40 bg-blue-500/10 hover:bg-blue-500/15 transition-all">
      <strong class="text-blue-400 text-sm">Trading Program</strong><br>
      <span class="text-xs opacity-80 mt-1 block">Limit order matching • CPI-based escrow • Atomic settlement • DvP protocol</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-yellow-500/40 bg-yellow-500/10 hover:bg-yellow-500/15 transition-all">
      <strong class="text-yellow-400 text-sm">SPL Token-2022</strong><br>
      <span class="text-xs opacity-80 mt-1 block">GTX energy tokens • USDC stablecoin • Transfer hooks • Metadata extension</span>
    </div>
  </div>
  <div class="flex justify-center items-center">
    <img src="/architecture/architecture_blockchain.svg" class="max-h-[440px] object-contain shadow-2xl rounded-lg" />
  </div>
</div>
