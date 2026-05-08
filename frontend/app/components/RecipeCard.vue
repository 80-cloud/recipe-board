<script setup lang="ts">
import type { RecipeSummary } from '~/types/recipe'

// S-01 のレシピカード（画面設計書 4-1）
// クリックで詳細画面 (S-02) へ遷移する想定（next Issue で実装）
defineProps<{ recipe: RecipeSummary }>()

function formatDate(iso: string): string {
  const d = new Date(iso)
  const yyyy = d.getFullYear()
  const mm = String(d.getMonth() + 1).padStart(2, '0')
  const dd = String(d.getDate()).padStart(2, '0')
  return `${yyyy}/${mm}/${dd}`
}
</script>

<template>
  <NuxtLink
    :to="`/recipes/${recipe.id}`"
    class="block rounded-lg border border-gray-200 bg-white p-5 shadow-sm transition hover:shadow-md focus:outline-none focus:ring-2 focus:ring-blue-400"
  >
    <h2 class="text-lg font-bold text-gray-900">{{ recipe.title }}</h2>
    <p class="mt-2 text-sm text-gray-500">{{ formatDate(recipe.created_at) }}</p>
  </NuxtLink>
</template>
