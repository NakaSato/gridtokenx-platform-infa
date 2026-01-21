<script setup lang="ts">
import FancyArrow from "slidev-addon-fancy-arrow/components/FancyArrow.vue";
</script>

<template>
  <FancyArrow v-bind="$attrs">
    <template v-for="(_, name) in $slots" #[name]="slotData">
      <slot :name="name" v-bind="slotData" />
    </template>
  </FancyArrow>
</template>
