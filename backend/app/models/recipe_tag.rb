class RecipeTag < ApplicationRecord
  belongs_to :recipe
  belongs_to :tag

  # 複合 unique は DB の idx_recipe_tags_recipe_tag_unique で担保
  validates :recipe_id, uniqueness: { scope: :tag_id }
end
