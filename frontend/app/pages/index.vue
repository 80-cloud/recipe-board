<script setup lang="ts">
// S-01: レシピ一覧画面（画面設計書 4-1）
// S-05 (Phase 2): タイトル部分一致検索バーを追加
const route = useRoute()
const router = useRouter()

// URL ?q= を初期値として読む（SSR/CSR 両対応 = X-01 hydration 罠対策）
const initialQ = typeof route.query.q === 'string' ? route.query.q : ''
const q = ref(initialQ)

// useRecipeList に reactive q を渡す → useFetch の query 変更で自動 refetch
const { recipes, pending, error, refresh } = useRecipeList(q)

// 入力 → URL ?q= 同期（300ms debounce で連続入力を抑制）
let debounceTimer: ReturnType<typeof setTimeout> | null = null
watch(q, (newVal) => {
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(() => {
    router.replace({ query: newVal ? { q: newVal } : {} })
  }, 300)
})
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <Header />

    <main class="mx-auto max-w-5xl px-6 py-8">
      <!-- 検索バー（S-05・タイトル部分一致） -->
      <div class="mb-6">
        <input
          v-model="q"
          type="search"
          placeholder="レシピタイトルを検索..."
          class="w-full rounded border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
          aria-label="レシピ検索"
        />
      </div>

      <LoadingSkeleton v-if="pending" />
      <ErrorState v-else-if="error" @retry="refresh()" />
      <EmptyState v-else-if="!recipes || recipes.length === 0" />
      <div
        v-else
        class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3"
      >
        <RecipeCard
          v-for="recipe in recipes"
          :key="recipe.id"
          :recipe="recipe"
        />
      </div>
    </main>
  </div>
</template>
