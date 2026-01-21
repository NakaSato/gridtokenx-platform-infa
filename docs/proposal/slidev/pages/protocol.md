# III-A. Trading Protocol Specification

<div class="grid grid-cols-2 gap-6 mt-6">
  <div class="flex flex-col gap-2 text-sm">
    <div v-click class="p-3 rounded-lg border border-[#14f195]/40 bg-[#14f195]/10 hover:bg-[#14f195]/15 transition-all">
      <strong class="text-[#14f195] text-sm">📝 Order Creation</strong><br>
      <span class="text-xs opacity-80 mt-1 block">Limit orders submitted via `create_order` instruction • Escrow locks THB (buyer) or GTX (seller) • Order stored in PDA</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-purple-500/40 bg-purple-500/10 hover:bg-purple-500/15 transition-all">
      <strong class="text-purple-400 text-sm">🔄 Order Matching</strong><br>
      <span class="text-xs opacity-80 mt-1 block">Off-chain engine calculates landed cost • Best price-time priority • On-chain verification via CPI</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-blue-500/40 bg-blue-500/10 hover:bg-blue-500/15 transition-all">
      <strong class="text-blue-400 text-sm">⚡ Atomic Settlement</strong><br>
      <span class="text-xs opacity-80 mt-1 block">Single TX executes: GTX transfer, THB payment, fee distribution • All-or-nothing guarantee</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-orange-500/40 bg-orange-500/10 hover:bg-orange-500/15 transition-all">
      <strong class="text-orange-400 text-sm">🔐 State Validation</strong><br>
      <span class="text-xs opacity-80 mt-1 block">Anchor constraints verify account ownership • Balance checks • Signature validation</span>
    </div>
  </div>
  <div class="flex flex-col gap-3">
    <div class="p-4 rounded-lg border border-gray-600 bg-gray-800/30">
      <h3 class="text-sm font-bold text-[#14f195] mb-3">Order Lifecycle States</h3>
      <div class="space-y-2 text-xs">
        <div class="flex items-center gap-2">
          <div class="w-3 h-3 rounded-full bg-yellow-400"></div>
          <span><strong>PENDING</strong> • Awaiting match</span>
        </div>
        <div class="flex items-center gap-2">
          <div class="w-3 h-3 rounded-full bg-blue-400"></div>
          <span><strong>PARTIAL</strong> • Partially filled</span>
        </div>
        <div class="flex items-center gap-2">
          <div class="w-3 h-3 rounded-full bg-green-400"></div>
          <span><strong>FILLED</strong> • Fully executed</span>
        </div>
        <div class="flex items-center gap-2">
          <div class="w-3 h-3 rounded-full bg-red-400"></div>
          <span><strong>CANCELLED</strong> • User cancelled</span>
        </div>
        <div class="flex items-center gap-2">
          <div class="w-3 h-3 rounded-full bg-gray-400"></div>
          <span><strong>EXPIRED</strong> • TTL exceeded</span>
        </div>
      </div>
    </div>
    <div class="p-4 rounded-lg border border-gray-600 bg-gray-800/30">
      <h3 class="text-sm font-bold text-purple-400 mb-2">Performance SLA</h3>
      <div class="space-y-1 text-xs opacity-80">
        <div>• Order latency: <strong class="text-green-400">&lt;100ms</strong></div>
        <div>• Settlement finality: <strong class="text-green-400">&lt;1s</strong></div>
        <div>• Throughput: <strong class="text-green-400">850 TPS</strong></div>
      </div>
    </div>
  </div>
</div>

---

# III-B. Oracle Data Protocol

<div class="grid grid-cols-2 gap-6 mt-6">
  <div class="flex flex-col gap-2 text-sm">
    <div v-click class="p-3 rounded-lg border border-yellow-500/40 bg-yellow-500/10 hover:bg-yellow-500/15 transition-all">
      <strong class="text-yellow-400 text-sm">🔌 Meter Registration</strong><br>
      <span class="text-xs opacity-80 mt-1 block">Registry program creates PDA with seeds: `[b"meter", meter_id, owner]` • Stores public key for Ed25519 verification</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-orange-500/40 bg-orange-500/10 hover:bg-orange-500/15 transition-all">
      <strong class="text-orange-400 text-sm">📊 Data Submission</strong><br>
      <span class="text-xs opacity-80 mt-1 block">Smart meter signs telemetry: `{timestamp, kWh, signature}` • Kafka transports to Rust consumer • Batched on-chain submission</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-green-500/40 bg-green-500/10 hover:bg-green-500/15 transition-all">
      <strong class="text-green-400 text-sm">✅ On-Chain Verification</strong><br>
      <span class="text-xs opacity-80 mt-1 block">Oracle program validates Ed25519 signature • Checks timestamp freshness (&lt;5 min) • Updates meter PDA state</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-purple-500/40 bg-purple-500/10 hover:bg-purple-500/15 transition-all">
      <strong class="text-purple-400 text-sm">🪙 Tokenization</strong><br>
      <span class="text-xs opacity-80 mt-1 block">Verified kWh triggers GTX minting • 1 kWh = 1000 GTX (µWh precision) • CPI to Token-2022 program</span>
    </div>
  </div>
  <div class="flex flex-col gap-3">
    <div class="p-4 rounded-lg border border-gray-600 bg-gray-800/30">
      <h3 class="text-sm font-bold text-yellow-400 mb-3">Data Validation Rules</h3>
      <div class="space-y-2 text-xs">
        <div v-click class="p-2 rounded bg-gray-700/30 border border-gray-600/30">
          <strong class="text-green-400">✓</strong> Signature matches registered meter pubkey
        </div>
        <div v-click class="p-2 rounded bg-gray-700/30 border border-gray-600/30">
          <strong class="text-green-400">✓</strong> Timestamp within 5-minute window
        </div>
        <div v-click class="p-2 rounded bg-gray-700/30 border border-gray-600/30">
          <strong class="text-green-400">✓</strong> kWh value within physical bounds (0-10 kW)
        </div>
        <div v-click class="p-2 rounded bg-gray-700/30 border border-gray-600/30">
          <strong class="text-green-400">✓</strong> No replay attacks (nonce monotonicity)
        </div>
      </div>
    </div>
    <div class="p-4 rounded-lg border border-gray-600 bg-gray-800/30">
      <h3 class="text-sm font-bold text-orange-400 mb-2">Telemetry Format</h3>
      <pre class="text-[10px] bg-black/40 p-2 rounded overflow-x-auto"><code>{
  "meter_id": "MTR_001",
  "timestamp": 1737460800,
  "energy_kwh": 2.45,
  "nonce": 12847,
  "signature": "0x4a7b..."
}</code></pre>
    </div>
  </div>
</div>

---

# III-C. Settlement & Fee Protocol

<div class="grid grid-cols-2 gap-4 mt-4">
  <div class="flex flex-col gap-1.5 text-sm">
    <div v-click class="p-2 rounded border border-cyan-500/40 bg-cyan-500/10">
      <strong class="text-cyan-400 text-xs">💰 Escrow Mechanism</strong><br>
      <span class="text-[11px] opacity-70">PDA escrow: `[b"escrow", order_id]` • THB/GTX locked • Auto-refund</span>
    </div>
    <div v-click class="p-2 rounded border border-blue-500/40 bg-blue-500/10">
      <strong class="text-blue-400 text-xs">🔄 Delivery vs Payment</strong><br>
      <span class="text-[11px] opacity-70">CPI chain: GTX transfer → THB payment → Fee split • Atomic rollback</span>
    </div>
    <div v-click class="p-2 rounded border border-purple-500/40 bg-purple-500/10">
      <strong class="text-purple-400 text-xs">⚖️ Fee Distribution</strong><br>
      <span class="text-[11px] opacity-70">Platform: 0.1% • Wheeling: 1.151 THB/kWh • Validators: 0.05%</span>
    </div>
    <div v-click class="p-2 rounded border border-green-500/40 bg-green-500/10">
      <strong class="text-green-400 text-xs">📉 Loss Compensation</strong><br>
      <span class="text-[11px] opacity-70">3-7% transmission loss • Seller: full THB • Buyer: net energy</span>
    </div>
  </div>
  <div class="flex flex-col gap-2">
    <div class="p-3 rounded border border-gray-600 bg-gray-800/30">
      <h3 class="text-xs font-bold text-cyan-400 mb-2">Settlement Formulas</h3>
      <div class="text-[10px] space-y-1">
        <div class="p-1.5 rounded bg-blue-500/10">
          <code class="text-blue-300">landed_cost = base + wheeling + loss</code>
        </div>
        <div class="p-1.5 rounded bg-purple-500/10">
          <code class="text-purple-300">buyer_pays = landed_cost × kWh</code>
        </div>
        <div class="p-1.5 rounded bg-green-500/10">
          <code class="text-green-300">seller_gets = base × kWh × (1 - fees)</code>
        </div>
      </div>
    </div>
    <div class="p-3 rounded border border-gray-600 bg-gray-800/30">
      <h3 class="text-xs font-bold text-purple-400 mb-1.5">Example: 10 kWh @ 3.50 THB/kWh</h3>
      <div class="text-[10px] space-y-0.5 opacity-80">
        <div class="flex justify-between">
          <span>Wheeling Charge:</span>
          <strong class="text-yellow-400">1.151 THB</strong>
        </div>
        <div class="flex justify-between">
          <span>Loss (5%):</span>
          <strong class="text-red-400">0.5 kWh</strong>
        </div>
        <div class="flex justify-between">
          <span>Platform (0.1%):</span>
          <strong class="text-blue-400">0.035 THB</strong>
        </div>
        <div class="border-t border-gray-600 pt-1 mt-1 space-y-0.5">
          <div class="flex justify-between">
            <span>Buyer pays:</span>
            <strong class="text-[#14f195]">46.51 THB</strong>
          </div>
          <div class="flex justify-between">
            <span>Seller gets:</span>
            <strong class="text-[#14f195]">34.97 THB</strong>
          </div>
          <div class="flex justify-between">
            <span>Delivered:</span>
            <strong class="text-[#14f195]">9.5 kWh</strong>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

---

# III-D. Consensus & Validation Protocol

<div class="grid grid-cols-2 gap-6 mt-6">
  <div class="flex flex-col gap-2 text-sm">
    <div v-click class="p-3 rounded-lg border border-[#14f195]/40 bg-[#14f195]/10 hover:bg-[#14f195]/15 transition-all">
      <strong class="text-[#14f195] text-sm">🔐 Proof of Authority</strong><br>
      <span class="text-xs opacity-80 mt-1 block">3 authorized validators • Multi-sig governance for validator rotation • Stake requirement: 1M SOL equivalent</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-purple-500/40 bg-purple-500/10 hover:bg-purple-500/15 transition-all">
      <strong class="text-purple-400 text-sm">⏱️ Block Production</strong><br>
      <span class="text-xs opacity-80 mt-1 block">400ms slot time • Tower BFT consensus • 1.3 second finality guarantee • Optimistic confirmation</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-orange-500/40 bg-orange-500/10 hover:bg-orange-500/15 transition-all">
      <strong class="text-orange-400 text-sm">✅ Transaction Validation</strong><br>
      <span class="text-xs opacity-80 mt-1 block">Signature verification • Account state checks • Compute budget limits (200K units) • Fee payment validation</span>
    </div>
    <div v-click class="p-3 rounded-lg border border-blue-500/40 bg-blue-500/10 hover:bg-blue-500/15 transition-all">
      <strong class="text-blue-400 text-sm">🔄 State Replication</strong><br>
      <span class="text-xs opacity-80 mt-1 block">Turbine block propagation • RPC nodes sync from validators • Geyser plugin for real-time updates</span>
    </div>
  </div>
  <div class="flex flex-col gap-3">
    <div class="p-4 rounded-lg border border-gray-600 bg-gray-800/30">
      <h3 class="text-sm font-bold text-[#14f195] mb-3">Validator Configuration</h3>
      <div class="space-y-2 text-xs">
        <div class="flex justify-between p-2 rounded bg-gray-700/30">
          <span class="opacity-70">Network Role</span>
          <strong class="text-purple-400">Block Producer</strong>
        </div>
        <div class="flex justify-between p-2 rounded bg-gray-700/30">
          <span class="opacity-70">Vote Credits</span>
          <strong class="text-green-400">100% uptime target</strong>
        </div>
        <div class="flex justify-between p-2 rounded bg-gray-700/30">
          <span class="opacity-70">Commission</span>
          <strong class="text-yellow-400">5% rewards</strong>
        </div>
        <div class="flex justify-between p-2 rounded bg-gray-700/30">
          <span class="opacity-70">Slashing Condition</span>
          <strong class="text-red-400">&gt;20% missed votes</strong>
        </div>
      </div>
    </div>
    <div class="p-4 rounded-lg border border-gray-600 bg-gray-800/30">
      <h3 class="text-sm font-bold text-purple-400 mb-3">Network Guarantees</h3>
      <div class="space-y-2 text-xs">
        <div class="flex items-start gap-2">
          <div class="text-green-400 mt-0.5">✓</div>
          <div><strong>Safety:</strong> 2/3 validator agreement required</div>
        </div>
        <div class="flex items-start gap-2">
          <div class="text-green-400 mt-0.5">✓</div>
          <div><strong>Liveness:</strong> Progress guaranteed with 1 honest validator</div>
        </div>
        <div class="flex items-start gap-2">
          <div class="text-green-400 mt-0.5">✓</div>
          <div><strong>Finality:</strong> Irreversible after 32 confirmations (~13s)</div>
        </div>
      </div>
    </div>
  </div>
</div>
