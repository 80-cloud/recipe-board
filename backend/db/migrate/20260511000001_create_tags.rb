class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      # タグ名: 1-50 文字、unique（同名タグは 1 レコード）
      t.string :name, null: false, limit: 50

      t.timestamps
    end

    # 同じ name のタグは作れないように unique 制約
    add_index :tags, :name, unique: true, name: "idx_tags_name_unique"
  end
end
