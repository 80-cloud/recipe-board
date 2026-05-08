class Step < ApplicationRecord
  belongs_to :recipe

  # バリデーション（DB設計書 5-2）
  validates :description, presence: true
  validates :position, presence: true,
                       numericality: { only_integer: true, greater_than: 0 }
end
