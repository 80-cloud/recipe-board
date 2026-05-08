import type { RecipeSummary, RecipeDetail, RecipeInput } from '~/types/recipe'

/**
 * レシピ一覧を取得する composable（S-01 用）
 *
 * 設計判断:
 *   - SSR でも fetch することで初回アクセスから Cards を描画（EmptyState フラッシュ回避）
 *   - useFetch の key で SSR/CSR の重複 fetch を抑止
 *   - エラーは ref で公開し、コンポーネント側でリトライ可能にする
 *   - default を [] にして data が null の状態を防ぐ（テンプレ側の v-if 簡素化）
 */
export function useRecipeList() {
  const config = useRuntimeConfig()
  const apiBase = config.public.apiBase

  const { data, pending, error, refresh } = useFetch<RecipeSummary[]>(
    `${apiBase}/recipes`,
    {
      key: 'recipe-list',
      default: () => [],
    },
  )

  return { recipes: data, pending, error, refresh }
}

/**
 * レシピ詳細を取得する composable（S-02 用）
 *
 * ドローン投下で確認した教訓:
 *   - error.value?.statusCode のみで分岐（body スキーマに依存しない）
 *   - dev モードと production モードで 404 body 形式が異なるため
 */
export function useRecipeDetail(id: string | number) {
  const config = useRuntimeConfig()
  const apiBase = config.public.apiBase

  const { data, pending, error, refresh } = useFetch<RecipeDetail>(
    `${apiBase}/recipes/${id}`,
    {
      key: `recipe-${id}`,
    },
  )

  return { recipe: data, pending, error, refresh }
}

/**
 * レシピ削除（S-02 削除モーダル経由）
 * 成功時 204 No Content（body なし）
 */
export async function deleteRecipe(id: number): Promise<void> {
  const config = useRuntimeConfig()
  const apiBase = config.public.apiBase

  await $fetch(`${apiBase}/recipes/${id}`, {
    method: 'DELETE',
  })
}

/**
 * レシピ新規登録（S-03 用）
 *
 * 奇襲囮で確認した教訓:
 *   - 成功時 201 + 完全な詳細 JSON（RecipeDetail）が返る
 *   - 失敗時 422 + { errors: { title: [...], ... } } が返る
 *   - $fetch は 4xx/5xx で throw する → catch で error.data.errors を取り出す
 */
export async function createRecipe(input: RecipeInput): Promise<RecipeDetail> {
  const config = useRuntimeConfig()
  const apiBase = config.public.apiBase

  return await $fetch<RecipeDetail>(`${apiBase}/recipes`, {
    method: 'POST',
    body: { recipe: input },
  })
}
