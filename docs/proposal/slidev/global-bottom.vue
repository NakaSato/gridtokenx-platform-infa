<template>
  <footer
    v-if="$nav.currentPage !== 1"
    class="absolute bottom-0 left-0 right-0 p-3 flex justify-between items-center w-full z-50 text-xs text-gray-400 font-kanit bg-gradient-to-t from-black/50 to-transparent"
  >
    <div class="ml-4 flex items-center gap-2">
      <span class="font-bold">Project GridTokenX</span>
      <span class="opacity-50">|</span>
      <span>Computer Engineering and Artificial Intelligence</span>
    </div>
    <div class="mr-4 opacity-70">
      {{ $nav.currentPage }} / {{ $nav.total }}
    </div>
  </footer>
</template>
