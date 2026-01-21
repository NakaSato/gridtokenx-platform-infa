# I. Core Architecture (Tri-Layer)

<div class="grid grid-cols-2 gap-8 mt-12">
  <div class="flex flex-col gap-6">
    <div v-click class="p-4 rounded border border-gray-700 bg-gray-800/20">
      <strong>L1 - Consensus:</strong><br>
      <span class="text-sm opacity-80">Solana (PoA) for truth & settlement</span>
    </div>
    <div v-click class="p-4 rounded border border-gray-700 bg-gray-800/20">
      <strong>L2 - Middleware:</strong><br>
      <span class="text-sm opacity-80">Rust API Gateway & Matching Engine</span>
    </div>
    <div v-click class="p-4 rounded border border-gray-700 bg-gray-800/20">
      <strong>L3 - Edge:</strong><br>
      <span class="text-sm opacity-80">IoT Simulators & Smart Meters</span>
    </div>
  </div>
  <div class="flex justify-center items-center">
    <img src="/solana-l1-architecture.svg" class="max-h-[380px]" />
  </div>
</div>

---

# II. Container Diagram

<div class="grid grid-cols-2 gap-8">
  <div class="text-sm">
    <p class="mb-4 opacity-70">High-level system containers and their responsibilities</p>
    <div v-click class="p-3 mb-2 rounded border border-gray-800 bg-gray-900/40">
      <strong>Trading Platform</strong> Next.js<br>
      <span class="text-xs opacity-60">Web dashboard for trading, monitoring energy production, and wallet management</span>
    </div>
    <div v-click class="p-3 mb-2 rounded border border-gray-800 bg-gray-900/40">
      <strong>API Gateway</strong> Rust middleware<br>
      <span class="text-xs opacity-60">High-performance matching engine, order book management, and state orchestration</span>
    </div>
    <div v-click class="p-3 mb-2 rounded border border-gray-800 bg-gray-900/40">
      <strong>Database</strong> PostgreSQL<br>
      <span class="text-xs opacity-60">Persistent storage for user profiles, orders, and transaction history</span>
    </div>
    <div v-click class="p-3 mb-2 rounded border border-gray-800 bg-gray-900/40">
      <strong>Blockchain:</strong> Solana PoA Validators<br>
      <span class="text-xs opacity-60">Decentralized ledger for energy token minting, settlement, and registry consensus</span>
    </div>
  </div>
   <div class="flex justify-center items-start mt-14">
    <img src="/container-diagram.svg" class="max-h-[420px] object-contain" />
  </div>
</div>
