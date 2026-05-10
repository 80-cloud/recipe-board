class Recipe < ApplicationRecord
  # 関連（DB設計書 5-1 / タグは 5-3 m:n）
  has_many :ingredients, -> { order(:position, :id) }, dependent: :destroy
  has_many :steps,       -> { order(:position, :id) }, dependent: :destroy
  has_many :recipe_tags, dependent: :destroy
  has_many :tags, through: :recipe_tags

  # ネスト属性: レシピと一緒に材料・手順を保存できるようにする
  accepts_nested_attributes_for :ingredients, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :steps,       allow_destroy: true, reject_if: :all_blank

  # バリデーション（DB設計書 5-2）
  validates :title, presence: true, length: { maximum: 100 }

  # タグ writer: フロントから ["和食", "簡単"] のような string 配列で受け取り、
  # find_or_create_by で重複排除しつつ既存タグを再利用する
  # 空文字・空白のみは除外
  attr_reader :tags_input

  def tags_input=(values)
    @tags_input = values
    @tags_input_provided = true
  end

  after_save :sync_tags_input, if: -> { @tags_input_provided }

  private

  def sync_tags_input
    cleaned = Array(@tags_input)
              .map { |v| v.to_s.strip }
              .reject(&:blank?)
              .uniq
    self.tags = cleaned.map { |name| Tag.find_or_create_by(name: name) }
    @tags_input_provided = false
  end
end
