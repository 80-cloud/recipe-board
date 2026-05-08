class CreateRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :recipes do |t|
      t.string :title, null: false, limit: 100

      t.timestamps
    end

    # DB 設計書 セクション 4 のインデックス設計
    add_index :recipes, :created_at, order: { created_at: :desc }, name: "idx_recipes_created_at"
  end
end
