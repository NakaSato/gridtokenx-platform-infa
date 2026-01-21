# VI. Performance Results

<div class="mt-12 p-6 rounded border border-gray-800 bg-gray-900/50">
  <table class="w-full text-lg">
    <thead>
      <tr class="border-b border-gray-800">
        <th class="text-left py-4 text-[#9945FF]">Metric</th>
        <th class="text-left py-4">Target Requirement</th>
        <th class="text-left py-4">Actual Result</th>
      </tr>
    </thead>
    <tbody>
      <tr v-click class="border-b border-gray-800/50">
        <td class="py-4">Throughput</td>
        <td>500 TPS</td>
        <td class="text-green-400 font-bold">850 TPS ✅</td>
      </tr>
      <tr v-click class="border-b border-gray-800/50">
        <td class="py-4">Finality</td>
        <td>< 2.0s</td>
        <td class="text-green-400 font-bold">0.8s ✅</td>
      </tr>
      <tr v-click>
        <td class="py-4">Latency</td>
        <td>< 100ms</td>
        <td class="text-green-400 font-bold">12ms ✅</td>
      </tr>
    </tbody>
  </table>
</div>

---

# VI-A. Security & Protection

<div class="grid grid-cols-1 gap-6 mt-12">
  <div v-click class="p-6 rounded border border-green-500/30 bg-green-500/5 flex items-center gap-6">
    <div class="text-3xl">🛡️</div>
    <div>
      <strong class="text-xl">Replay Protection</strong><br>
      <span class="opacity-80">Nonce/Slot check enforced at PoA Consensus Layer</span>
    </div>
  </div>
  <div v-click class="p-6 rounded border border-green-500/30 bg-green-500/5 flex items-center gap-6">
    <div class="text-3xl">🔒</div>
    <div>
      <strong class="text-xl">Double Spend Prevention</strong><br>
      <span class="opacity-80">On-chain Atomic Escrow ensures funds are only spent once</span>
    </div>
  </div>
  <div v-click class="p-6 rounded border border-green-500/30 bg-green-500/5 flex items-center gap-6">
    <div class="text-3xl">🔑</div>
    <div>
      <strong class="text-xl">PDA Signers</strong><br>
      <span class="opacity-80">Secure seed-based authority (Program Derived Addresses)</span>
    </div>
  </div>
</div>

---
layout: center
class: text-center
---

# ขอบคุณครับ

Questions & Answers

<div class="mt-12 opacity-60">
  <h4 class="text-[#14f195] text-2xl text-semibold">GridTokenX Project</h4>
  <p>Energy for a Sustainable Future</p>
</div>
