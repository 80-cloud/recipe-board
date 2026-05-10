class Tag < ApplicationRecord
  has_many :recipe_tags, dependent: :destroy
  has_many :recipes, through: :recipe_tags

  # バリデーション（DB設計書 5-3 / unique は DB の idx_tags_name_unique と整合）
  validates :name, presence: true,
                   length: { maximum: 50 },
                   uniqueness: true
end
