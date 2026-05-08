# 開発用シードデータ
#
# 実行: bin/rails db:seed
#
# 安全装置:
#   - production では実行しない（誤って本番に開発用データを入れない）
#   - 既存データがあれば追加投入をスキップ（冪等性）
#
# 関連:
#   - DB 設計書セクション 9（シードデータの方針）
#   - 画面設計書 S-01（レシピ一覧画面の動作確認用）

if Rails.env.production?
  Rails.logger.warn "[seeds.rb] production では seed を実行しません。"
  exit
end

if Recipe.exists?
  Rails.logger.info "[seeds.rb] 既存レシピがあるため seed をスキップ。"
  exit
end

ActiveRecord::Base.transaction do
  Recipe.create!(
    title: "鶏の唐揚げ",
    ingredients_attributes: [
      { name: "鶏もも肉", quantity: "300g",     position: 1 },
      { name: "醤油",     quantity: "大さじ 2", position: 2 },
      { name: "酒",       quantity: "大さじ 1", position: 3 }
    ],
    steps_attributes: [
      { description: "鶏肉を一口大に切る",              position: 1 },
      { description: "調味料を混ぜて 30 分漬け込む",     position: 2 },
      { description: "片栗粉をまぶして 170 度で揚げる",  position: 3 }
    ]
  )

  Recipe.create!(
    title: "肉じゃが",
    ingredients_attributes: [
      { name: "牛肉",       quantity: "200g", position: 1 },
      { name: "じゃがいも", quantity: "3 個", position: 2 },
      { name: "玉ねぎ",     quantity: "1 個", position: 3 }
    ],
    steps_attributes: [
      { description: "野菜を切る",              position: 1 },
      { description: "肉と野菜を炒める",         position: 2 },
      { description: "出汁・醤油・砂糖で煮込む", position: 3 }
    ]
  )

  Recipe.create!(
    title: "味噌汁",
    ingredients_attributes: [
      { name: "豆腐",   quantity: "1/2 丁",   position: 1 },
      { name: "わかめ", quantity: "適量",     position: 2 },
      { name: "味噌",   quantity: "大さじ 2", position: 3 }
    ],
    steps_attributes: [
      { description: "出汁を取る",      position: 1 },
      { description: "具材を煮る",      position: 2 },
      { description: "味噌を溶き入れる", position: 3 }
    ]
  )
end

Rails.logger.info "[seeds.rb] レシピ #{Recipe.count} 件投入完了。"
