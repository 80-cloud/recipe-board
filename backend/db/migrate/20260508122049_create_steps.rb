class CreateSteps < ActiveRecord::Migration[8.1]
  def change
    create_table :steps do |t|
      # ON DELETE CASCADE: レシピ削除時に手順も自動削除（DB設計書 5-1）
      t.references :recipe, null: false, foreign_key: { on_delete: :cascade }
      t.integer :position, null: false
      t.text :description, null: false

      t.timestamps
    end

    # 複合インデックス: 手順の番号順取得を高速化（DB設計書 4）
    add_index :steps, [ :recipe_id, :position ], name: "idx_steps_recipe_position"
  end
end
