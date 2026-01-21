# II-A. Anchor Smart Contracts

<div class="grid grid-cols-2 gap-8 mt-12">
  <div class="flex flex-col gap-3">
    <div v-click class="p-3 rounded border border-purple-500/30 bg-purple-500/5">
      <strong>1. Registry:</strong> PDAs for 10,000+ meters<br>
    </div>
    <div v-click class="p-3 rounded border border-purple-500/30 bg-purple-500/5">
      <strong>2. Oracle:</strong> IoT signature verification<br>
    </div>
    <div v-click class="p-3 rounded border border-purple-500/30 bg-purple-500/5">
      <strong>3. Token:</strong> SPL-2022 Mint/Burn/Transfer<br>
    </div>
    <div v-click class="p-3 rounded border border-purple-500/30 bg-purple-500/5">
      <strong>4. Trading:</strong> Order book & escrow<br>
    </div>
    <div v-click class="p-3 rounded border border-purple-500/30 bg-purple-500/5">
      <strong>5. Governance:</strong> Fee & role management<br>
    </div>
  </div>
  <div class="flex justify-center items-start animate-bounce-slow">
    <img src="/component-anchor-program.svg" class="max-h-[400px]" />
  </div>
</div>

---

# II-A-1. Registry Program

<div class="grid grid-cols-2 gap-8 mt-12">
  <div class="text-sm">
    <div v-click class="p-4 mb-3 rounded border border-gray-700 bg-gray-800/20">
      <strong>PDA Derivation:</strong> Deterministic seeds<br>
      <span class="text-xs opacity-60">Generate unique on-chain addresses from meter_id + owner_pubkey for collision-free registry</span>
    </div>
    <div v-click class="p-4 mb-3 rounded border border-gray-700 bg-gray-800/20">
      <strong>Meter Binding:</strong> Link IoT to Wallet<br>
      <span class="text-xs opacity-60">Immutable association between physical smart meter and Solana wallet address</span>
    </div>
    <div v-click class="p-4 mb-3 rounded border border-gray-700 bg-gray-800/20">
      <strong>Status Tracking:</strong> Registry State Machine<br>
      <span class="text-xs opacity-60">Track lifecycle states: Pending → Active → Suspended → Decommissioned</span>
    </div>
  </div>
  <div class="flex justify-center items-center">
    <img src="/component-anchor-registry.svg" class="max-h-[380px]" />
  </div>
</div>

---

# II-A-2. Oracle Program

<div class="grid grid-cols-2 gap-8 mt-12 items-start">
  <div class="text-sm">
    <div v-click class="p-4 mb-3 rounded border border-purple-500/30 bg-purple-500/5">
      <strong>1. Signature:</strong> Ed25519 Proof<br>
      <span class="text-xs opacity-60">Cryptographic verification that telemetry data originates from authorized IoT device</span>
    </div>
    <div v-click class="p-4 mb-3 rounded border border-purple-500/30 bg-purple-500/5">
      <strong>2. Validation:</strong> Slot/Timestamp Check<br>
      <span class="text-xs opacity-60">Ensure data freshness and prevent replay attacks using Solana clock constraints</span>
    </div>
    <div v-click class="p-4 mb-3 rounded border border-purple-500/30 bg-purple-500/5">
      <strong>3. Normalization:</strong> Unit Conversion<br>
      <span class="text-xs opacity-60">Standardize energy readings to kWh and apply grid loss factors for accurate billing</span>
    </div>
  </div>
  <div v-click class="flex justify-center items-center">
    <img src="/component-anchor-oracle.svg" class="max-h-[380px]" />
  </div>
</div>

---

# II-A-3. Trading & Escrow

<div class="grid grid-cols-2 gap-8 mt-12">
  <div class="text-sm">
    <div v-click class="p-4 mb-3 rounded border border-purple-500/30 bg-purple-500/5">
      <strong>Limit Orders:</strong> Price-time priority<br>
      <span class="text-xs opacity-60">On-chain order book matching engine with FIFO execution at same price levels</span>
    </div>
    <div v-click class="p-4 mb-3 rounded border border-purple-500/30 bg-purple-500/5">
      <strong>Escrow Accounts:</strong> Secured tokens<br>
      <span class="text-xs opacity-60">Lock energy tokens in program-controlled PDAs until settlement or cancellation</span>
    </div>
    <div v-click class="p-4 mb-3 rounded border border-purple-500/30 bg-purple-500/5">
      <strong>Atomic Settlement:</strong> DvP Guarantee<br>
      <span class="text-xs opacity-60">Delivery-versus-Payment ensures simultaneous token and payment exchange or full rollback</span>
    </div>
  </div>
  <div class="flex justify-center items-center">
    <img src="/component-anchor-trading.svg" class="max-h-[380px]" />
  </div>
</div>
