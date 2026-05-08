module Api
  class RecipesController < BaseController
    # GET /api/recipes
    # 画面設計書 4-1 S-01: レシピ一覧（作成日降順）
    def index
      recipes = Recipe.order(created_at: :desc)
      render json: recipes.as_json(only: [ :id, :title, :created_at, :updated_at ])
    end
  end
end
