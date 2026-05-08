<script setup lang="ts">
// 「← 戻る」リンク（画面設計書 5）
defineProps<{ to: string; label?: string }>()
</script>

<template>
  <NuxtLink
    :to="to"
    class="inline-flex items-center text-sm text-gray-600 hover:text-gray-900"
  >
    <span class="mr-1">←</span>{{ label ?? '一覧へ戻る' }}
  </NuxtLink>
</template>
