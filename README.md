# レシピ管理アプリ (Recipe Board)

> 学習用のレシピ管理 Web アプリケーション。
> 自分の作ったレシピを登録・管理・閲覧できるシンプルなアプリです。

---

## プロジェクト概要

| 項目 | 内容 |
|---|---|
| 目的 | 個人のレシピを Web 上で管理・共有できるアプリの開発 |
| 学習目的 | Ruby on Rails / Vue.js (Nuxt) / MySQL の習得、AWS 無料枠での本番デプロイ経験 |
| 開発者 | hideharu-AI |
| 開発期間 | 2026年5月〜 |
| 開発手法 | Issue ファースト・PR ベースのワークフロー（Claude Code 併用） |

---

## 技術スタック

### バックエンド
- **言語**: Ruby 3.x
- **フレームワーク**: Ruby on Rails 7.x（API モード）
- **DB**: MySQL 8.x（Docker コンテナ）

### フロントエンド
- **フレームワーク**: Nuxt 3（Vue.js 3 ベース）
- **CSS**: Tailwind CSS（予定）
- **ビルドツール**: Vite

### インフラ・運用
- **本番デプロイ先**: AWS EC2 + RDS（無料枠の範囲内）
- **IaC**: Terraform
- **Web サーバー**: Nginx（リバースプロキシ）

### 開発ツール
- **バージョン管理**: Git / GitHub
- **コンテナ**: Docker Compose（ローカル開発の DB 用）
- **AI 開発支援**: Claude Code を活用

---

## ディレクトリ構成（予定）

```
recipe-board/
├── README.md                  ← このファイル
├── CLAUDE.md                  ← Claude Code の行動規範
├── .gitignore
├── .github/
│   ├── ISSUE_TEMPLATE/
│   └── pull_request_template.md
├── docs/                      ← 設計ドキュメント（要件定義書・DB設計書 等）
├── docker-compose.yml         ← ローカル MySQL 起動用
├── backend/                   ← Rails アプリケーション
└── frontend/                  ← Nuxt アプリケーション
```

> 各フォルダは Phase ごとに順次追加していきます。

---

## 使用ポート

| サービス | ポート |
|---|---|
| Rails (バックエンド) | 3000 |
| Nuxt (フロントエンド) | 3001 |
| MySQL (DB) | 3306 |

> ポート競合時は CLAUDE.md セクション 10 のルールに従い、**正規ポートで起動**します。

---

## セットアップ手順

> ※ 開発が進み次第、具体的な手順を追記していきます。

### 前提

- macOS / Linux
- Docker Desktop インストール済み
- Ruby 3.x（rbenv 等で管理）
- Node.js v22 以上

### ローカル起動（予定）

```bash
# 1. リポジトリをクローン
git clone https://github.com/80-cloud/recipe-board.git
cd recipe-board

# 2. 環境変数を設定（初回のみ）
cp .env.example .env
# .env を編集して実際の値を記入（パスワード等）

# 3. pre-commit hook を有効化（開発者のみ・読むだけなら不要）
brew install pre-commit gitleaks
pre-commit install

# 4. MySQL を Docker で起動
docker-compose up -d

# 5. バックエンド（Rails）を起動
cd backend
bundle install
rails db:migrate
rails s -p 3000

# 6. フロントエンド（Nuxt）を起動
cd frontend
npm install
npm run dev
```

### 機密情報の取り扱い（重要）

本リポジトリでは前プロジェクトでの機密情報漏洩事故の教訓を踏まえ、**pre-commit hook で機密情報を自動スキャン**しています。

- パスワード・API キー・トークン等を `.env` 以外に書かないこと
- `.env` は `.gitignore` で除外済み（コミットされない）
- `git commit` 時に gitleaks が自動で検知してブロック

**閲覧目的でクローンする場合は pre-commit のインストールは不要**（読むだけなら影響なし）。

---

## 開発状況

- [x] リポジトリ初期化
- [ ] 要件定義書の作成
- [ ] 画面設計書の作成
- [ ] DB 設計書の作成
- [ ] 技術スタック確定
- [ ] バックエンド初期セットアップ
- [ ] フロントエンド初期セットアップ
- [ ] CRUD 機能の実装
- [ ] AWS デプロイ

---

## 開発ルール

本リポジトリの開発・運用ルールは以下に記載しています。

- [`OPERATIONS.md`](./OPERATIONS.md) — **プロジェクト運用方針**（リポジトリ閲覧者・講師向け）
- [`CLAUDE.md`](./CLAUDE.md) — **Claude Code 行動規範**（AI/開発者向け詳細ルール）
- [`docs/learning-notes.md`](./docs/learning-notes.md) — 開発中の学び・事故記録（PDCA(S) の S）

主な内容:
- ブランチ命名規則
- Issue ファースト・ワークフロー
- コミットメッセージ規則（Conventional Commits / 日本語）
- PR 規則
- 禁止事項（破壊的操作の制限、AI 誤操作防止）
- トヨタ式 PDCA(S) と安心・安全ファースト作業方針

---

## ライセンス

学習用個人プロジェクト（提出予定）
