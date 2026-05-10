class CreateRecipeTags < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_tags do |t|
      # ON DELETE CASCADE: レシピ削除時に関連も自動削除
      t.references :recipe, null: false, foreign_key: { on_delete: :cascade }
      # ON DELETE CASCADE: タグ削除時に関連も自動削除
      t.references :tag,    null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    # 同じ recipe-tag 組合せは作れない（重複付与防止）
    add_index :recipe_tags, [ :recipe_id, :tag_id ], unique: true,
              name: "idx_recipe_tags_recipe_tag_unique"
  end
end
