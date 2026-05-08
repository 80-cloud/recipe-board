import type { RecipeSummary } from '~/types/recipe'

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
