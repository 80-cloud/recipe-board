<script setup lang="ts">
import type {
  IngredientInput,
  StepInput,
  RecipeInput,
  ValidationErrors,
} from '~/types/recipe'

// S-04: レシピ編集（画面設計書 4-4）
//
// ドローンで確認した教訓:
//   - nested attrs の 3 状態（id 付き更新 / id 無し新規 / _destroy 削除）が
//     混在送信で同時に処理される
//   - 既存基盤（accepts_nested_attributes_for + Strong Params）が S-03 で
//     確立済みのため、PATCH 拡張部分も予測内で安定動作
//
// 戦略 3（選択的 B 適用）の新ドメイン部分:
//   - 既存値の reactive state 流し込み
//   - 削除フラグの UI 管理（既存 = _destroy: true / 新規 = 配列即削除）

const route = useRoute()
const id = route.params.id as string

const { recipe, pending, error } = useRecipeDetail(id)

const title = ref('')
// 編集中の行を表す中間型: _destroy フラグ付き
type IngredientRow = IngredientInput & { _destroy?: boolean }
type StepRow = StepInput & { _destroy?: boolean }

const ingredients = ref<IngredientRow[]>([])
const steps = ref<StepRow[]>([])
const tagsInputRaw = ref('') // #112 タグ機能: カンマ区切り文字列で UI 編集

// 既存値が取れたら reactive state へ流し込み（structuredClone で deep copy）
watch(
  recipe,
  (val) => {
    if (!val) return
    title.value = val.title
    ingredients.value = structuredClone(val.ingredients).map((it) => ({
      id: it.id,
      name: it.name,
      quantity: it.quantity ?? '',
      position: it.position,
    }))
    steps.value = structuredClone(val.steps).map((it) => ({
      id: it.id,
      description: it.description,
      position: it.position,
    }))
    tagsInputRaw.value = formatTagsInput(val.tags ?? []) // #112: 既存タグを ", " 結合で初期化
  },
  { immediate: true },
)

const isSubmitting = ref(false)
const errors = ref<ValidationErrors>({})
const submitError = ref<string | null>(null)

const titleRemaining = computed(() => 100 - title.value.length)
const visibleIngredients = computed(() => ingredients.value.filter((it) => !it._destroy))
const visibleSteps = computed(() => steps.value.filter((it) => !it._destroy))

function addIngredient() {
  ingredients.value.push({
    name: '',
    quantity: '',
    position: visibleIngredients.value.length + 1,
  })
}
function removeIngredient(item: IngredientRow) {
  if (item.id) {
    // 既存行 → _destroy フラグで送信して削除
    item._destroy = true
  } else {
    // 新規行 → 配列から即削除
    const idx = ingredients.value.indexOf(item)
    if (idx >= 0) ingredients.value.splice(idx, 1)
  }
}
function addStep() {
  steps.value.push({
    description: '',
    position: visibleSteps.value.length + 1,
  })
}
function removeStep(item: StepRow) {
  if (item.id) {
    item._destroy = true
  } else {
    const idx = steps.value.indexOf(item)
    if (idx >= 0) steps.value.splice(idx, 1)
  }
}

async function onSubmit() {
  if (!recipe.value) return
  isSubmitting.value = true
  errors.value = {}
  submitError.value = null

  // visible 行のみ position 再採番。_destroy フラグ付き行はそのまま送信。
  let pos = 1
  const validIngredients = ingredients.value.map((it) => {
    if (it._destroy) return it
    if (it.name.trim() === '' && !it.id) {
      // 新規空白行は除外（S-03 と同じ罠対処）
      return { ...it, _destroy: true } as IngredientRow
    }
    return { ...it, position: pos++ }
  })
  pos = 1
  const validSteps = steps.value.map((it) => {
    if (it._destroy) return it
    if (it.description.trim() === '' && !it.id) {
      return { ...it, _destroy: true } as StepRow
    }
    return { ...it, position: pos++ }
  })

  const payload: RecipeInput = {
    title: title.value,
    ingredients_attributes: validIngredients,
    steps_attributes: validSteps,
    tags_input: parseTagsInput(tagsInputRaw.value), // #112 タグ機能
  }

  try {
    const updated = await updateRecipe(recipe.value.id, payload)
    // useFetch のクライアントキャッシュを破棄（詳細 + 一覧）
    // ブラウザ実機で詳細画面に古い値が残る罠（光学迷彩）への対処
    clearNuxtData(`recipe-${updated.id}`)
    clearNuxtData('recipe-list')
    await navigateTo(`/recipes/${updated.id}`)
  } catch (e: unknown) {
    const err = e as { data?: { errors?: ValidationErrors }; statusCode?: number }
    if (err.statusCode === 422 && err.data?.errors) {
      errors.value = err.data.errors
    } else {
      submitError.value = '保存に失敗しました。時間を置いて再度お試しください。'
    }
    isSubmitting.value = false
  }
}
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <Header />

    <main class="mx-auto max-w-3xl px-6 py-8">
      <BackLink :to="`/recipes/${id}`" label="キャンセル（詳細へ戻る）" />

      <div class="mt-6">
        <LoadingSkeleton v-if="pending" />
        <div
          v-else-if="error?.statusCode === 404"
          class="rounded-lg border border-amber-200 bg-amber-50 p-8 text-center"
        >
          <p class="text-lg font-medium text-amber-800">レシピが見つかりません</p>
        </div>
        <ErrorState v-else-if="error" @retry="$router.go(0)" />

        <form
          v-else-if="recipe"
          class="rounded-lg border border-gray-200 bg-white p-8 shadow-sm"
          @submit.prevent="onSubmit"
        >
          <h1 class="text-2xl font-bold text-gray-900">レシピを編集</h1>

          <p
            v-if="submitError"
            class="mt-4 rounded-md border border-red-200 bg-red-50 p-3 text-sm text-red-700"
          >
            {{ submitError }}
          </p>

          <div class="mt-6">
            <label for="title" class="block text-sm font-medium text-gray-900">
              タイトル <span class="text-red-600">*</span>
            </label>
            <input
              id="title"
              v-model="title"
              type="text"
              maxlength="100"
              required
              class="mt-1 w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-200"
            >
            <p class="mt-1 text-xs text-gray-500">残り {{ titleRemaining }} 文字</p>
            <p
              v-for="msg in errors.title"
              :key="msg"
              class="mt-1 text-xs text-red-600"
            >
              {{ msg }}
            </p>
          </div>

          <!-- タグ（#112: カンマ区切り） -->
          <div class="mt-6">
            <label for="tags" class="block text-sm font-medium text-gray-900">
              タグ
            </label>
            <input
              id="tags"
              v-model="tagsInputRaw"
              type="text"
              placeholder="和食, 簡単, 夕食"
              class="mt-1 w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-200"
            >
            <p class="mt-1 text-xs text-gray-500">カンマ（, または 、）で区切って入力</p>
          </div>

          <section class="mt-8">
            <h2 class="border-b border-gray-200 pb-2 text-lg font-bold text-gray-900">材料</h2>
            <div class="mt-3 space-y-2">
              <div
                v-for="(ing, idx) in visibleIngredients"
                :key="ing.id ?? `new-${idx}`"
                class="flex gap-2"
              >
                <input
                  v-model="ing.name"
                  type="text"
                  placeholder="名前"
                  maxlength="100"
                  class="flex-1 rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-200"
                >
                <input
                  v-model="ing.quantity"
                  type="text"
                  placeholder="分量"
                  maxlength="50"
                  class="w-32 rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-200"
                >
                <button
                  type="button"
                  class="rounded-md border border-gray-300 bg-white px-3 py-2 text-sm text-gray-700 hover:bg-gray-50"
                  @click="removeIngredient(ing)"
                >
                  削除
                </button>
              </div>
            </div>
            <button
              type="button"
              class="mt-3 text-sm text-blue-700 hover:text-blue-900"
              @click="addIngredient"
            >
              ＋ 材料を追加
            </button>
          </section>

          <section class="mt-8">
            <h2 class="border-b border-gray-200 pb-2 text-lg font-bold text-gray-900">手順</h2>
            <div class="mt-3 space-y-2">
              <div
                v-for="(step, idx) in visibleSteps"
                :key="step.id ?? `new-${idx}`"
                class="flex items-start gap-2"
              >
                <span class="mt-2 flex-none text-sm font-bold text-gray-700">{{ idx + 1 }}.</span>
                <textarea
                  v-model="step.description"
                  rows="2"
                  placeholder="手順を入力"
                  class="flex-1 rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-200"
                />
                <button
                  type="button"
                  class="rounded-md border border-gray-300 bg-white px-3 py-2 text-sm text-gray-700 hover:bg-gray-50"
                  @click="removeStep(step)"
                >
                  削除
                </button>
              </div>
            </div>
            <button
              type="button"
              class="mt-3 text-sm text-blue-700 hover:text-blue-900"
              @click="addStep"
            >
              ＋ 手順を追加
            </button>
          </section>

          <div class="mt-8 flex justify-end gap-3">
            <NuxtLink
              :to="`/recipes/${id}`"
              class="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
            >
              キャンセル
            </NuxtLink>
            <button
              type="submit"
              :disabled="isSubmitting"
              class="rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
            >
              {{ isSubmitting ? '保存中...' : '保存' }}
            </button>
          </div>
        </form>
      </div>
    </main>
  </div>
</template>
