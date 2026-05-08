<script setup lang="ts">
// S-01 / S-02 / S-03 共通ヘッダー（画面設計書 4-1）
</script>

<template>
  <header class="border-b border-gray-200 bg-white">
    <div class="mx-auto flex max-w-5xl items-center justify-between px-6 py-4">
      <NuxtLink to="/" class="text-xl font-bold text-gray-900 hover:text-gray-700">
        recipe-board
      </NuxtLink>
      <NuxtLink
        to="/recipes/new"
        class="rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-400"
      >
        ＋ 新規レシピ
      </NuxtLink>
    </div>
  </header>
</template>
