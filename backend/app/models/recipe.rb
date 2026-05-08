class Recipe < ApplicationRecord
  # 関連（DB設計書 5-1）
  has_many :ingredients, -> { order(:position, :id) }, dependent: :destroy
  has_many :steps,       -> { order(:position, :id) }, dependent: :destroy

  # ネスト属性: レシピと一緒に材料・手順を保存できるようにする
  accepts_nested_attributes_for :ingredients, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :steps,       allow_destroy: true, reject_if: :all_blank

  # バリデーション（DB設計書 5-2）
  validates :title, presence: true, length: { maximum: 100 }
end
