class CreateIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :ingredients do |t|
      # ON DELETE CASCADE: レシピ削除時に材料も自動削除（DB設計書 5-1）
      t.references :recipe, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false, limit: 100
      t.string :quantity, limit: 50
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    # 複合インデックス: 材料の表示順取得を高速化（DB設計書 4）
    add_index :ingredients, [ :recipe_id, :position ], name: "idx_ingredients_recipe_position"
  end
end
