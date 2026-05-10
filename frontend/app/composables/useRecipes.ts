import type { RecipeSummary, RecipeDetail, RecipeInput } from '~/types/recipe'

/**
 * レシピ一覧を取得する composable（S-01 用 / S-05 検索対応）
 *
 * 設計判断:
 *   - SSR でも fetch することで初回アクセスから Cards を描画（EmptyState フラッシュ回避）
 *   - useFetch の key で SSR/CSR の重複 fetch を抑止
 *   - エラーは ref で公開し、コンポーネント側でリトライ可能にする
 *   - default を [] にして data が null の状態を防ぐ（テンプレ側の v-if 簡素化）
 *   - q 引数: タイトル部分一致検索（S-05）。Ref で渡すと reactive に再 fetch
 *     ※ X-02 useFetch キャッシュ罠（2026-05-09）対策: query を computed で渡すことで
 *       q 変更時に Nuxt が自動的に refetch を行う（手動 refresh 不要）
 */
export function useRecipeList(q?: Ref<string>) {
  const config = useRuntimeConfig()
  const apiBase = config.public.apiBase

  const { data, pending, error, refresh } = useFetch<RecipeSummary[]>(
    `${apiBase}/recipes`,
    {
      key: 'recipe-list',
      default: () => [],
      query: computed(() => {
        const v = q?.value
        return v ? { q: v } : {}
      }),
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

/**
 * レシピ更新（S-04 用）
 *
 * ドローン D-1 で確認した教訓:
 *   - nested attrs に id 付きで送ると更新
 *   - id 無しで送ると新規追加
 *   - _destroy: true で送ると削除
 *   - 全 3 状態が混在送信で同時に処理される
 */
export async function updateRecipe(id: number, input: RecipeInput): Promise<RecipeDetail> {
  const config = useRuntimeConfig()
  const apiBase = config.public.apiBase

  return await $fetch<RecipeDetail>(`${apiBase}/recipes/${id}`, {
    method: 'PATCH',
    body: { recipe: input },
  })
}
