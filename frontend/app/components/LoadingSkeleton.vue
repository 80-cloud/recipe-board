<script setup lang="ts">
// 取得中のスケルトン UI（画面設計書 4-1）
</script>

<template>
  <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
    <div
      v-for="i in 6"
      :key="i"
      class="animate-pulse rounded-lg border border-gray-200 bg-white p-5"
    >
      <div class="h-5 w-3/4 rounded bg-gray-200" />
      <div class="mt-3 h-4 w-1/3 rounded bg-gray-100" />
    </div>
  </div>
</template>
