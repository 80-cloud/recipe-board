<script setup lang="ts">
// API 失敗時の表示（画面設計書 4-1）
defineEmits<{ retry: [] }>()
</script>

<template>
  <div class="rounded-lg border border-red-200 bg-red-50 p-8 text-center">
    <p class="text-lg font-medium text-red-700">読み込みに失敗しました</p>
    <p class="mt-2 text-sm text-red-600">時間を置いて再度お試しください。</p>
    <button
      type="button"
      class="mt-4 rounded-md bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700"
      @click="$emit('retry')"
    >
      再読み込み
    </button>
  </div>
</template>
