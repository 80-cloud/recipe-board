// レシピ関連の型定義
//
// 関連:
//   - 画面設計書 4-1〜4-4
//   - DB 設計書 3-1〜3-3
//   - backend/app/controllers/api/recipes_controller.rb の as_json 出力

/**
 * レシピ一覧の各要素（S-01 / GET /api/recipes）
 */
export interface RecipeSummary {
  id: number
  title: string
  created_at: string
  updated_at: string
}

/**
 * レシピ詳細の各要素（S-02 / GET /api/recipes/:id）
 * ドローン投下で確認した as_json 出力形式に対応。
 * order(:position, :id) で並び順保持されるためフロントでのソート不要。
 */
export interface Ingredient {
  id: number
  name: string
  quantity: string | null
  position: number
}

export interface Step {
  id: number
  description: string
  position: number
}

export interface RecipeDetail extends RecipeSummary {
  ingredients: Ingredient[]
  steps: Step[]
}
