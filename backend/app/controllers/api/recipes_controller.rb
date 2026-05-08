module Api
  class RecipesController < BaseController
    # GET /api/recipes
    # 画面設計書 4-1 S-01: レシピ一覧（作成日降順）
    def index
      recipes = Recipe.order(created_at: :desc)
      render json: recipes.as_json(only: [ :id, :title, :created_at, :updated_at ])
    end

    # GET /api/recipes/:id
    # 画面設計書 4-2 S-02: レシピ詳細（材料・手順を含む）
    # ドローン投下で確認した as_json 出力形式に合わせる
    def show
      recipe = Recipe.includes(:ingredients, :steps).find(params[:id])
      render json: serialize_detail(recipe)
    end

    # POST /api/recipes
    # 画面設計書 4-3 S-03: レシピ新規登録（材料・手順をネスト送信）
    # ドローン D-4 で Mass Assignment 起動を確認 → Strong Parameters で防御
    def create
      recipe = Recipe.new(recipe_params)
      if recipe.save
        render json: serialize_detail(recipe), status: :created
      else
        render json: { errors: recipe.errors.as_json }, status: :unprocessable_entity
      end
    end

    # DELETE /api/recipes/:id
    # 画面設計書 4-2 S-02: 削除モーダル経由で削除
    # dependent: :destroy で ingredients/steps も連動削除（ドローンで動作確認済）
    def destroy
      recipe = Recipe.find(params[:id])
      recipe.destroy!
      head :no_content
    end

    private

    # Strong Parameters（ドローン D-4 で Mass Assignment 起動確認済）
    # id / created_at / updated_at は permit しない
    def recipe_params
      params.require(:recipe).permit(
        :title,
        ingredients_attributes: [ :id, :name, :quantity, :position, :_destroy ],
        steps_attributes:       [ :id, :description, :position, :_destroy ]
      )
    end

    # show / create で共通利用する as_json 出力
    def serialize_detail(recipe)
      recipe.as_json(
        only: [ :id, :title, :created_at, :updated_at ],
        include: {
          ingredients: { only: [ :id, :name, :quantity, :position ] },
          steps:       { only: [ :id, :description, :position ] }
        }
      )
    end
  end
end
