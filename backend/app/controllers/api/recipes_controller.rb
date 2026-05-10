module Api
  class RecipesController < BaseController
    # ソート whitelist（要件定義書 3-2 Phase 2 / 無効値は SQL injection 対策で無視）
    SORT_OPTIONS = {
      "created_desc" => { created_at: :desc },
      "updated_desc" => { updated_at: :desc },
      "title_asc"    => { title: :asc }
    }.freeze
    DEFAULT_SORT = "created_desc"

    # GET /api/recipes
    # 画面設計書 4-1 S-01: レシピ一覧
    # S-05 (Phase 2): ?q= でタイトル部分一致検索（未指定時は全件）
    # #108  (Phase 2): ?sort= で並び順切替（whitelist 外は default に fallback）
    # #110  (Phase 2): tags をサマリーに含める（N+1 回避のため includes(:tags)）
    def index
      sort_key = SORT_OPTIONS.key?(params[:sort]) ? params[:sort] : DEFAULT_SORT
      scope = Recipe.includes(:tags).order(SORT_OPTIONS[sort_key])
      if params[:q].present?
        sanitized = ActiveRecord::Base.sanitize_sql_like(params[:q].to_s)
        scope = scope.where("title LIKE ?", "%#{sanitized}%")
      end
      render json: scope.map { |r| serialize_summary(r) }
    end

    # GET /api/recipes/:id
    # 画面設計書 4-2 S-02: レシピ詳細（材料・手順・タグを含む）
    # ドローン投下で確認した as_json 出力形式に合わせる
    def show
      recipe = Recipe.includes(:ingredients, :steps, :tags).find(params[:id])
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

    # PATCH /api/recipes/:id
    # 画面設計書 4-4 S-04: レシピ編集
    # ドローン D-1 で確認: nested attrs の既存更新 / 新規追加 / _destroy 削除の
    # 3 状態がすべて期待どおり機能する（accepts_nested_attributes_for + Strong Params）
    def update
      recipe = Recipe.find(params[:id])
      if recipe.update(recipe_params)
        render json: serialize_detail(recipe.reload)
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
    # tags_input は string array（["和食", "簡単"]）として permit
    def recipe_params
      params.require(:recipe).permit(
        :title,
        tags_input: [],
        ingredients_attributes: [ :id, :name, :quantity, :position, :_destroy ],
        steps_attributes:       [ :id, :description, :position, :_destroy ]
      )
    end

    # 一覧用サマリー（タグ名のみ、材料・手順は含めない）
    def serialize_summary(recipe)
      recipe.as_json(only: [ :id, :title, :created_at, :updated_at ])
            .merge("tags" => recipe.tags.map(&:name))
    end

    # show / create で共通利用する as_json 出力
    def serialize_detail(recipe)
      recipe.as_json(
        only: [ :id, :title, :created_at, :updated_at ],
        include: {
          ingredients: { only: [ :id, :name, :quantity, :position ] },
          steps:       { only: [ :id, :description, :position ] }
        }
      ).merge("tags" => recipe.tags.map(&:name))
    end
  end
end
