# ============================================
# CORS 設定 — Cross-Origin Resource Sharing
# ============================================
# task-board (前プロジェクト) で CORS の許可オリジンを localhost にハードコード
# したため、EC2 デプロイ時に POST が通らなくなる事故が発生（Phase 4.5）。
# その教訓継承で、本プロジェクトでは最初から **環境変数駆動**。
#
# 設定方法:
#   .env で CORS_ALLOWED_ORIGINS をカンマ区切りで指定
#   例: CORS_ALLOWED_ORIGINS=http://localhost:3001,http://example.com
#
# 関連:
#   - task-board incident: 2026-05-07-cors-rejected-ec2-ip
#   - DB 設計書 セクション 11
#   - .env の CORS_ALLOWED_ORIGINS
# ============================================

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # 環境変数からオリジンを読み込み（カンマ区切り）
    # 未設定の場合は localhost:3001 のみ許可（開発デフォルト）
    origins ENV.fetch("CORS_ALLOWED_ORIGINS", "http://localhost:3001").split(",").map(&:strip)

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      expose: [ "X-Total-Count" ]
  end
end
