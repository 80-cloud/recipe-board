Rails.application.routes.draw do
  # ヘルスチェック（ロードバランサー・監視用）
  get "up" => "rails/health#show", as: :rails_health_check

  # API は /api 配下に集約（画面設計書 4-1〜4-4 の /api/recipes 系と整合）
  namespace :api do
    resources :recipes, only: [ :index ]
  end
end
