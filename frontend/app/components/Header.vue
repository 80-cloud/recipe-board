<script setup lang="ts">
// S-01 ヘッダー（画面設計書 4-1）
// 「新規レシピ」ボタンは S-03 実装時に有効化する。
</script>

<template>
  <header class="border-b border-gray-200 bg-white">
    <div class="mx-auto flex max-w-5xl items-center justify-between px-6 py-4">
      <h1 class="text-xl font-bold text-gray-900">recipe-board</h1>
      <button
        type="button"
        disabled
        class="cursor-not-allowed rounded-md bg-gray-200 px-4 py-2 text-sm font-medium text-gray-500"
        title="次の Issue で実装予定"
      >
        ＋ 新規レシピ
      </button>
    </div>
  </header>
</template>
