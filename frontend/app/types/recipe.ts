// レシピ関連の型定義
//
// 関連:
//   - 画面設計書 4-1〜4-4
//   - DB 設計書 3-1〜3-3
//   - backend/app/controllers/api/recipes_controller.rb の as_json 出力

/**
 * レシピ一覧の各要素（S-01 / GET /api/recipes）
 * 詳細画面（S-02）では ingredients / steps を含む別型を使う想定。
 */
export interface RecipeSummary {
  id: number
  title: string
  created_at: string
  updated_at: string
}
