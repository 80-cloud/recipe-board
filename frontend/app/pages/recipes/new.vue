<script setup lang="ts">
import type {
  IngredientInput,
  StepInput,
  RecipeInput,
  ValidationErrors,
} from '~/types/recipe'

// S-03: レシピ新規登録（画面設計書 4-3）
//
// ドローン + 奇襲囮で得た教訓を反映:
//   - reject_if: :all_blank が position 入りで発火しない罠 → submit 直前に空白行を除外
//   - errors.as_json は { title: [...] } 構造（型 ValidationErrors）
//   - Mass Assignment は backend の Strong Parameters で防御済（permit のみ送信）
//   - $fetch は 4xx/5xx で throw → catch で error.data.errors を取り出す

const title = ref('')
const ingredients = ref<IngredientInput[]>([
  { name: '', quantity: '', position: 1 },
])
const steps = ref<StepInput[]>([
  { description: '', position: 1 },
])

const isSubmitting = ref(false)
const errors = ref<ValidationErrors>({})
const submitError = ref<string | null>(null)

const titleRemaining = computed(() => 100 - title.value.length)

function addIngredient() {
  ingredients.value.push({
    name: '',
    quantity: '',
    position: ingredients.value.length + 1,
  })
}
function removeIngredient(idx: number) {
  ingredients.value.splice(idx, 1)
}
function addStep() {
  steps.value.push({
    description: '',
    position: steps.value.length + 1,
  })
}
function removeStep(idx: number) {
  steps.value.splice(idx, 1)
}

async function onSubmit() {
  isSubmitting.value = true
  errors.value = {}
  submitError.value = null

  // 罠 2 対処: 空白行除外 + position 再採番
  const validIngredients = ingredients.value
    .filter((it) => it.name.trim() !== '')
    .map((it, i) => ({ ...it, position: i + 1 }))
  const validSteps = steps.value
    .filter((it) => it.description.trim() !== '')
    .map((it, i) => ({ ...it, position: i + 1 }))

  const payload: RecipeInput = {
    title: title.value,
    ingredients_attributes: validIngredients,
    steps_attributes: validSteps,
  }

  try {
    const created = await createRecipe(payload)
    // useFetch のクライアントキャッシュを破棄（一覧）
    // 一覧に新規レシピが反映されない罠（光学迷彩）への対処
    clearNuxtData('recipe-list')
    await navigateTo(`/recipes/${created.id}`)
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
      <BackLink to="/" label="キャンセル（一覧へ戻る）" />

      <form class="mt-6 rounded-lg border border-gray-200 bg-white p-8 shadow-sm" @submit.prevent="onSubmit">
        <h1 class="text-2xl font-bold text-gray-900">新規レシピ</h1>

        <p
          v-if="submitError"
          class="mt-4 rounded-md border border-red-200 bg-red-50 p-3 text-sm text-red-700"
        >
          {{ submitError }}
        </p>

        <!-- タイトル -->
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

        <!-- 材料 -->
        <section class="mt-8">
          <h2 class="border-b border-gray-200 pb-2 text-lg font-bold text-gray-900">材料</h2>
          <div class="mt-3 space-y-2">
            <div
              v-for="(ing, idx) in ingredients"
              :key="idx"
              class="flex gap-2"
            >
              <input
                v-model="ing.name"
                type="text"
                placeholder="名前（例: 鶏もも肉）"
                maxlength="100"
                class="flex-1 rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-200"
              >
              <input
                v-model="ing.quantity"
                type="text"
                placeholder="分量（例: 300g）"
                maxlength="50"
                class="w-32 rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-200"
              >
              <button
                type="button"
                class="rounded-md border border-gray-300 bg-white px-3 py-2 text-sm text-gray-700 hover:bg-gray-50"
                @click="removeIngredient(idx)"
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

        <!-- 手順 -->
        <section class="mt-8">
          <h2 class="border-b border-gray-200 pb-2 text-lg font-bold text-gray-900">手順</h2>
          <div class="mt-3 space-y-2">
            <div
              v-for="(step, idx) in steps"
              :key="idx"
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
                @click="removeStep(idx)"
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

        <!-- アクション -->
        <div class="mt-8 flex justify-end gap-3">
          <NuxtLink
            to="/"
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
    </main>
  </div>
</template>
