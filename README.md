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
- **フレームワーク**: Ruby on Rails 8.1.3（API モード）
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

### ローカル起動

```bash
# 1. リポジトリをクローン
git clone https://github.com/80-cloud/recipe-board.git
cd recipe-board

# 2. 環境変数を設定（初回のみ）
cp .env.example .env
# .env を編集して実際の値を記入（パスワード等）
# Rails の SECRET_KEY_BASE は `cd backend && bundle exec rails secret` で生成

# 3. pre-commit hook を有効化（開発者のみ・読むだけなら不要）
brew install pre-commit gitleaks
pre-commit install

# 4. Ruby 3.4.9 をインストール（rbenv 使用）
brew install rbenv ruby-build
echo 'eval "$(rbenv init - --no-rehash zsh)"' >> ~/.zshrc
source ~/.zshrc
rbenv install 3.4.9
rbenv global 3.4.9
gem install bundler rails

# 5. MySQL を Docker で起動（初回起動時に権限付与スクリプトが自動実行）
docker compose up -d

# 6. バックエンド（Rails）を起動
cd backend
bundle install
bin/rails db:create db:migrate
bin/rails s -p 3000

# 7. フロントエンド（Nuxt）を起動（別ターミナル）
cd frontend
npm install
npm run dev
# → http://localhost:3001 でアクセス
```

### 起動確認

| サービス | URL | 期待値 |
|---|---|---|
| Rails (API) | http://localhost:3000 | HTTP 200（Rails welcome page） |
| Nuxt (Frontend) | http://localhost:3001 | HTTP 200（Nuxt welcome page） |
| MySQL | port 3306 | docker ps で `(healthy)` 表示 |

### 停止

```bash
# Rails / Nuxt は Ctrl+C で停止
# MySQL を停止（データは保持）
docker compose stop

# MySQL を停止 + データ削除（⚠️ 開発データ消失）
docker compose down -v
```

### Production build の起動運用（提出 / デプロイ用）

開発時は `bin/rails s` + `npm run dev` で十分。Production build を確認する場合は以下：

```bash
# 1. Frontend を build
cd frontend
npm run build

# 2. Rails dev を 3000 で起動
cd ../backend
bin/rails s -p 3000 -d

# 3. Nuxt prod を 3002 で起動（3001 と分けて衝突回避）
cd ../frontend
NUXT_PUBLIC_API_BASE=http://localhost:3000/api NITRO_PORT=3002 \
  node .output/server/index.mjs
```

**注意**:

- `NUXT_PUBLIC_API_BASE` は Nuxt 起動時の環境変数で**実行時に解決**される（build に焼き込まれない）。本番デプロイで API URL が変わる場合は起動時に再指定すること。
- `NITRO_PORT` を指定しないと Nuxt prod は port 3000 で起動し Rails と衝突する。dev (3001) との混在も避けるため 3002 推奨。
- `Nuxt DevTools` は `nuxt.config.ts` で `devtools: { enabled: false }` に設定済み。これは [vue-router 5 hydration クラッシュ事故](../_templates/incident-library/2026-05-09-nuxt-devtools-vue-router-hydration.md)への対処。

### 機密情報の取り扱い（重要）

本リポジトリでは前プロジェクトでの機密情報漏洩事故の教訓を踏まえ、**pre-commit hook で機密情報を自動スキャン**しています。

- パスワード・API キー・トークン等を `.env` 以外に書かないこと
- `.env` は `.gitignore` で除外済み（コミットされない）
- `git commit` 時に gitleaks が自動で検知してブロック

**閲覧目的でクローンする場合は pre-commit のインストールは不要**（読むだけなら影響なし）。

---

## 開発状況

### 設計・実装フェーズ
- [x] リポジトリ初期化
- [x] 要件定義書の作成（[`docs/要件定義書.md`](docs/要件定義書.md)）
- [x] 画面設計書の作成（[`docs/画面設計書.md`](docs/画面設計書.md)）
- [x] DB 設計書の作成（[`docs/DB設計書.md`](docs/DB設計書.md)）
- [x] 技術スタック確定（Rails 8.1.3 + Nuxt 3 + MySQL 8.4）
- [x] バックエンド初期セットアップ（Rails API モード）
- [x] フロントエンド初期セットアップ（Nuxt 3 + TypeScript）
- [x] CRUD 機能の実装（S-01 一覧 / S-02 詳細 / S-03 新規 / S-04 編集）

### AWS デプロイフェーズ（Phase 4・進行中）
- [x] B-1〜B-3: AWS 現状確認 / task-board 停止 / Ruby version 強制
- [x] B-4-A: production 1-DB 化（PR #58）
- [x] B-5-α: `infra/.gitignore` 作成（PR #62）
- [x] B-5-β: `infra/main.tf` 骨格・VPC / SG（PR #64）
- [x] B-5-γ: `infra/main.tf` に EC2 / RDS / EIP 追記（PR #67）
- [x] B-5-δ: `variables.tf` / `outputs.tf` / `terraform.tfvars.example` 分離（PR #69）
- [ ] **B-5-ε: `infra/user_data.sh` 作成（次に着手）**
- [ ] B-6: `terraform init` + `plan`（read-only）
- [ ] B-7: plan レビュー（人間 + AI 二重チェック）

### 開発プロトコル / 運用基盤（修練城）
- [x] scout-drone-protocol v3.3（過去事故から学ぶ訓練フェーズ運用）
- [x] CLAUDE.md セクション 18（提出時運用モード）
- [x] incident-library 連携（過去事故の永続化）
- [x] Claude Code Hooks（D-GIT-01 / D-EC2-COUNT / port-conflict）
- [x] GitHub Actions 自動化（incident-watchdog / RDS auto-stop）

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
