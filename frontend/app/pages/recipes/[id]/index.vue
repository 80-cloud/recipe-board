<script setup lang="ts">
// S-02: レシピ詳細画面（画面設計書 4-2）
//
// ドローン投下で確認した教訓を反映:
//   - error.value?.statusCode のみで判定（body スキーマに依存しない）
//   - 全テキストは {{ }} のみで描画（v-html 禁止 = XSS 対策）
//   - dependent: :destroy でサーバ側が ingredients/steps も削除（確認済）
//   - position の order は API 側で保持されているのでフロントでソート不要

const route = useRoute()
const id = route.params.id as string

const { recipe, pending, error } = useRecipeDetail(id)

const isModalOpen = ref(false)
const isDeleting = ref(false)
const deleteError = ref<string | null>(null)

function formatDate(iso: string): string {
  const d = new Date(iso)
  const yyyy = d.getFullYear()
  const mm = String(d.getMonth() + 1).padStart(2, '0')
  const dd = String(d.getDate()).padStart(2, '0')
  return `${yyyy}/${mm}/${dd}`
}

async function onConfirmDelete() {
  if (!recipe.value) return
  isDeleting.value = true
  deleteError.value = null
  try {
    await deleteRecipe(recipe.value.id)
    // useFetch のクライアントキャッシュを破棄（一覧 + 自身）
    // 削除後の一覧に消えたレシピが残る罠（光学迷彩）への対処
    clearNuxtData(`recipe-${recipe.value.id}`)
    clearNuxtData('recipe-list')
    await navigateTo('/')
  } catch (e) {
    deleteError.value = '削除に失敗しました。時間を置いて再度お試しください。'
    isDeleting.value = false
  }
}
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <Header />

    <main class="mx-auto max-w-3xl px-6 py-8">
      <BackLink to="/" />

      <div class="mt-6">
        <LoadingSkeleton v-if="pending" />

        <div
          v-else-if="error?.statusCode === 404"
          class="rounded-lg border border-amber-200 bg-amber-50 p-8 text-center"
        >
          <p class="text-lg font-medium text-amber-800">レシピが見つかりません</p>
          <p class="mt-2 text-sm text-amber-700">削除されたか、URL が誤っている可能性があります。</p>
        </div>

        <ErrorState v-else-if="error" @retry="$router.go(0)" />

        <article v-else-if="recipe" class="rounded-lg border border-gray-200 bg-white p-8 shadow-sm">
          <h1 class="text-2xl font-bold text-gray-900">{{ recipe.title }}</h1>

          <p class="mt-2 text-sm text-gray-500">
            作成: {{ formatDate(recipe.created_at) }}
            <span v-if="recipe.updated_at !== recipe.created_at" class="ml-3">
              更新: {{ formatDate(recipe.updated_at) }}
            </span>
          </p>

          <div class="mt-4 flex gap-2">
            <NuxtLink
              :to="`/recipes/${recipe.id}/edit`"
              class="rounded-md border border-blue-300 bg-white px-4 py-2 text-sm font-medium text-blue-700 hover:bg-blue-50"
            >
              編集
            </NuxtLink>
            <button
              type="button"
              class="rounded-md border border-red-300 bg-white px-4 py-2 text-sm font-medium text-red-700 hover:bg-red-50"
              @click="isModalOpen = true"
            >
              削除
            </button>
          </div>

          <p
            v-if="deleteError"
            class="mt-3 rounded-md border border-red-200 bg-red-50 p-3 text-sm text-red-700"
          >
            {{ deleteError }}
          </p>

          <section class="mt-8">
            <h2 class="border-b border-gray-200 pb-2 text-lg font-bold text-gray-900">材料</h2>
            <ul class="mt-3 space-y-2">
              <li
                v-for="ing in recipe.ingredients"
                :key="ing.id"
                class="flex items-baseline gap-3 text-sm"
              >
                <span class="font-medium text-gray-900">・{{ ing.name }}</span>
                <span class="text-gray-600">{{ ing.quantity }}</span>
              </li>
              <li v-if="recipe.ingredients.length === 0" class="text-sm text-gray-500">
                材料は登録されていません
              </li>
            </ul>
          </section>

          <section class="mt-8">
            <h2 class="border-b border-gray-200 pb-2 text-lg font-bold text-gray-900">手順</h2>
            <ol class="mt-3 space-y-3">
              <li
                v-for="(step, idx) in recipe.steps"
                :key="step.id"
                class="flex gap-3 text-sm"
              >
                <span class="flex-none font-bold text-gray-700">{{ idx + 1 }}.</span>
                <span class="whitespace-pre-wrap text-gray-800">{{ step.description }}</span>
              </li>
              <li v-if="recipe.steps.length === 0" class="text-sm text-gray-500">
                手順は登録されていません
              </li>
            </ol>
          </section>
        </article>
      </div>
    </main>

    <DeleteConfirmModal
      :open="isModalOpen"
      :recipe-title="recipe?.title ?? ''"
      :busy="isDeleting"
      @cancel="isModalOpen = false"
      @confirm="onConfirmDelete"
    />
  </div>
</template>
