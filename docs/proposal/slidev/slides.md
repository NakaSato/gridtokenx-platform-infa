---
# theme id, package name, or local path
theme: seriph
# background image
background: /backgrounds/space-bg.jpg
# default class for all slides
class: text-right

# addons
addons:
  - fancy-arrow
  - tikzjax

# title of your slide
title: UTCC Final Project
# titleTemplate for the webpage
titleTemplate: '%s - Slidev'

# information for your slides
info: false

# enable presenter mode
presenter: true
# enable browser exporter
browserExporter: dev
# enabled pdf downloading in SPA build
download: false
# filename of the export file
exportFilename: slidev-exported
# export options
export:
  format: pdf
  timeout: 30000
  dark: false
  withClicks: false
  withToc: false

# highlighter
highlighter: shiki
# show line numbers in code blocks
lineNumbers: true

# enable twoslash
twoslash: true
# enable monaco editor
monaco: true
# Where to load monaco types from
monacoTypesSource: local

# download remote assets in local using vite-plugin-remote-assets
remoteAssets: false
# controls whether texts in slides are selectable
selectable: true
# enable slide recording
record: dev
# enable Slidev's context menu
contextMenu: true
# enable wake lock
wakeLock: true
# take snapshot for each slide in the overview
overviewSnapshots: false

# force color schema for the slides
colorSchema: auto
# router mode for vue-router
routerMode: history
# aspect ratio for the slides
aspectRatio: 16/9
# real width of the canvas
canvasWidth: 980

# theme customization
themeConfig:
  primary: '#5d8392'

# transition
transition: slide-left

# fonts
fonts:
  sans: Inter
  serif: Roboto Serif
  mono: JetBrains Mono
  header: Kanit

# drawing options
drawings:
  enabled: true
  persist: false
  presenterOnly: false
  syncAll: true

# HTML tag attributes
htmlAttrs:
  dir: ltr
  lang: en

# SEO meta tags
seoMeta:
  ogTitle: UTCC Final Project
  ogDescription: GridTokenX Platform Infrastructure Proposal
  twitterCard: summary_large_image
---

# การพัฒนาระบบจำลองการซื้อขายพลังงานแสงอาทิตย์แบบ Peer-to-Peer ด้วย Solana Smart Contract

## (Anchor Framework in Permissioned Environments)

<div class="mt-20 flex flex-row gap-10 justify-end">
  <div class="text-right">
    <p class="font-kanit text-lg m-0 text-gray-400"><strong>ผู้จัดทำ: </strong> นายจันทร์ธวัฒ กิริยาดี</p>
  </div>
  <div class="text-right border-l border-gray-700 pl-10">
    <p class="font-kanit text-lg m-0 text-gray-400"><strong>อาจารย์ที่ปรึกษา: </strong> ดร.สุวรรณี อัศวกุลชัย</p>
  </div>
</div>

---
background: /backgrounds/space-bg.jpg
class: text-left
---

<div class="top-5 w-2/3 text-left">
  <h1 class="!mb-4 !mt-0 text-4xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-white to-white/70">Agenda</h1>

  <div class="flex flex-col gap-2">
    <div v-click class="px-4 py-2 rounded-lg border border-white/10 bg-white/5 backdrop-blur-sm hover:bg-white/10 hover:border-solana-green/30 transition-all duration-300">
      <span class="text-solana-green font-mono mr-3 text-lg">01.</span> <span class="text-white font-semibold text-base">Core Architecture</span> <span class="text-solana-purple/80 text-xs ml-2 font-mono">(System Layers)</span>
    </div>
    <div v-click class="px-4 py-2 rounded-lg border border-white/10 bg-white/5 backdrop-blur-sm hover:bg-white/10 hover:border-solana-green/30 transition-all duration-300">
      <span class="text-solana-green font-mono mr-3 text-lg">02.</span> <span class="text-white font-semibold text-base">Innovations</span> <span class="text-solana-purple/80 text-xs ml-2 font-mono">(PoA & Speed)</span>
    </div>
    <div v-click class="px-4 py-2 rounded-lg border border-white/10 bg-white/5 backdrop-blur-sm hover:bg-white/10 hover:border-solana-green/30 transition-all duration-300">
      <span class="text-solana-green font-mono mr-3 text-lg">03.</span> <span class="text-white font-semibold text-base">System Workflow</span> <span class="text-solana-purple/80 text-xs ml-2 font-mono">(Step-by-Step)</span>
    </div>
    <div v-click class="px-4 py-2 rounded-lg border border-white/10 bg-white/5 backdrop-blur-sm hover:bg-white/10 hover:border-solana-green/30 transition-all duration-300">
      <span class="text-solana-green font-mono mr-3 text-lg">04.</span> <span class="text-white font-semibold text-base">Economic Model</span> <span class="text-solana-purple/80 text-xs ml-2 font-mono">(Sustainability)</span>
    </div>
    <div v-click class="px-4 py-2 rounded-lg border border-white/10 bg-white/5 backdrop-blur-sm hover:bg-white/10 hover:border-solana-green/30 transition-all duration-300">
      <span class="text-solana-green font-mono mr-3 text-lg">05.</span> <span class="text-white font-semibold text-base">Simulation & UI</span> <span class="text-solana-purple/80 text-xs ml-2 font-mono">(Frontend)</span>
    </div>
    <div v-click class="px-4 py-2 rounded-lg border border-white/10 bg-white/5 backdrop-blur-sm hover:bg-white/10 hover:border-solana-green/30 transition-all duration-300">
      <span class="text-solana-green font-mono mr-3 text-lg">06.</span> <span class="text-white font-semibold text-base">Timeline</span>
    </div>
  </div>
</div>

---

---
src: ./pages/architecture.md
---

---
src: ./pages/architecture-details.md
---

---
src: ./pages/architecture-layers.md
---

---
src: ./pages/tech-stack.md
---

---
src: ./pages/smart-contracts.md
---

---
src: ./pages/innovation.md
---

---
src: ./pages/protocol.md
---

---
src: ./pages/workflow.md
---

---
src: ./pages/economics.md
---

---
src: ./pages/simulation.md
---

---
src: ./pages/results.md
---