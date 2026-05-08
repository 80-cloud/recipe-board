class Ingredient < ApplicationRecord
  belongs_to :recipe

  # バリデーション（DB設計書 5-2）
  validates :name, presence: true, length: { maximum: 100 }
  validates :quantity, length: { maximum: 50 }, allow_blank: true
end
