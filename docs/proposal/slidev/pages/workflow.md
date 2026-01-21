# IV. System Workflow (Happy Path)

<div class="flex flex-col gap-4 mt-12">
  <div v-click class="p-4 rounded border border-green-500/30 bg-green-500/5">
    <strong>1. Tokenization:</strong> Energy from smart meters minted as <span class="text-[#14f195]">GTX tokens</span>.
  </div>
  <div v-click class="p-4 rounded border border-green-500/30 bg-green-500/5">
    <strong>2. Escrow:</strong> Buy/Sell orders lock funds into <span class="text-[#14f195]">secure escrow</span>.
  </div>
  <div v-click class="p-4 rounded border border-[#14f195]/30 bg-[#14f195]/5">
    <strong>3. Matching:</strong> Engine matches via <span class="text-green-400">"Landed Cost"</span> (Price + Zonal Fees + Loss).
  </div>
  <div v-click class="p-4 rounded border border-purple-500/30 bg-purple-500/5">
    <strong>4. Atomic Settlement:</strong> Single transaction settlement (No counterparty risk).
  </div>
</div>

---

# IV-A. Transaction Atomicity

<div class="grid grid-cols-2 gap-8 mt-8">
  <div class="flex flex-col gap-2 text-sm">
    <div v-click class="p-4 rounded border border-purple-500/30 bg-purple-500/5">
      <strong class="text-purple-400">Single Transaction Settlement</strong><br>
      <span class="text-xs opacity-70">All operations (token transfer, payment, fee distribution) execute atomically or rollback completely</span>
    </div>
    <div v-click class="p-4 rounded border border-purple-500/30 bg-purple-500/5">
      <strong class="text-purple-400">Landed Cost Formula</strong><br>
      <span class="text-xs opacity-70">Final Price = Base Price + Wheeling Fee + Transmission Loss Factor</span>
    </div>
    <div v-click class="p-4 rounded border border-purple-500/30 bg-purple-500/5">
      <strong class="text-purple-400">Energy Accounting</strong><br>
      <span class="text-xs opacity-70">Only effective energy delivered to buyer after grid losses; seller receives full payment</span>
    </div>
    <div v-click class="p-4 rounded border border-purple-500/30 bg-purple-500/5">
      <strong class="text-purple-400">Zero Counterparty Risk</strong><br>
      <span class="text-xs opacity-70">Escrow guarantees funds availability; no possibility of failed settlement or partial execution</span>
    </div>
  </div>
  <div class="flex justify-center items-center">
    <img src="/transaction-atomicity.svg" class="max-h-[400px] object-contain" />
  </div>
</div>
