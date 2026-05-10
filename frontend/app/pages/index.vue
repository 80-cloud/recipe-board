<script setup lang="ts">
// S-01: レシピ一覧画面（画面設計書 4-1）
// S-05 (Phase 2): タイトル部分一致検索バー
// #108 (Phase 2): ソート（作成日順 / 更新日順 / タイトル順）
const route = useRoute()
const router = useRouter()

// ソート whitelist（backend SORT_OPTIONS と整合 / 値だけは UI で持つ）
const SORT_LABELS: Record<string, string> = {
  created_desc: '作成日（新しい順）',
  updated_desc: '更新日（新しい順）',
  title_asc: 'タイトル順',
}
const DEFAULT_SORT = 'created_desc'

const initialQ = typeof route.query.q === 'string' ? route.query.q : ''
const initialSort =
  typeof route.query.sort === 'string' && SORT_LABELS[route.query.sort]
    ? route.query.sort
    : DEFAULT_SORT

const q = ref(initialQ)
const sort = ref(initialSort)

const { recipes, pending, error, refresh } = useRecipeList(q, sort)

// 入力 → URL ?q= 同期（300ms debounce）
let qDebounceTimer: ReturnType<typeof setTimeout> | null = null
watch(q, (newVal) => {
  if (qDebounceTimer) clearTimeout(qDebounceTimer)
  qDebounceTimer = setTimeout(() => {
    syncUrl({ q: newVal, sort: sort.value })
  }, 300)
})

// sort 変更は debounce 不要（即座に URL 更新）
watch(sort, (newVal) => {
  syncUrl({ q: q.value, sort: newVal })
})

function syncUrl(state: { q: string; sort: string }) {
  const query: Record<string, string> = {}
  if (state.q) query.q = state.q
  if (state.sort && state.sort !== DEFAULT_SORT) query.sort = state.sort
  router.replace({ query })
}
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <Header />

    <main class="mx-auto max-w-5xl px-6 py-8">
      <!-- 検索 + ソート（S-05 / #108） -->
      <div class="mb-6 flex flex-col gap-3 sm:flex-row">
        <input
          v-model="q"
          type="search"
          placeholder="レシピタイトルを検索..."
          class="flex-1 rounded border border-gray-300 px-4 py-2 focus:border-blue-500 focus:outline-none"
          aria-label="レシピ検索"
        />
        <select
          v-model="sort"
          class="rounded border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none sm:w-56"
          aria-label="並び順"
        >
          <option
            v-for="(label, value) in SORT_LABELS"
            :key="value"
            :value="value"
          >
            {{ label }}
          </option>
        </select>
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
