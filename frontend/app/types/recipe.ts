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

/**
 * 新規登録 / 編集フォーム用の入力型（S-03 / S-04）
 * 既存レコードは id 付き、新規行は id 無し。
 * MVP ではフロント側の position は配列 index + 1 で submit 直前に再採番。
 */
export interface IngredientInput {
  id?: number
  name: string
  quantity: string
  position: number
}

export interface StepInput {
  id?: number
  description: string
  position: number
}

export interface RecipeInput {
  title: string
  ingredients_attributes: IngredientInput[]
  steps_attributes: StepInput[]
}

/**
 * バックエンド errors.as_json の構造（ドローン D-3 で確認済）
 * 例: { title: ["can't be blank"] }
 */
export type ValidationErrors = Record<string, string[]>
