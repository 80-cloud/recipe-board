# OPERATIONS.md — プロジェクト運用方針

> 本リポジトリの**開発手法・運用ルール・AI 利用方針**をまとめた、リポジトリ閲覧者向けの説明書。
> 詳細な行動規範は `CLAUDE.md`、開発上の学びは `docs/learning-notes.md` を参照。

---

## 1. プロジェクト位置付け

| 項目 | 内容 |
|---|---|
| 種別 | 学習用個人プロジェクト（スクール提出物） |
| 開発者 | 1 名（hideharu-AI） |
| 開発期間 | 2026 年 5 月 〜 |
| AI 利用 | Claude Code を活用（スクールから推奨） |
| 提出形態 | GitHub URL 提出 |

---

## 2. 開発手法

本プロジェクトは「**現場の流れに沿った開発手法を踏襲する**」ことを最重要視している。

### 2-1. Issue ファースト・ワークフロー

```
GitHub Issue 起票
     ↓
ブランチ作成（feature/#番号-説明 等）
     ↓
実装・コミット（Conventional Commits 形式・日本語）
     ↓
PR 作成（テンプレート使用・Closes #番号 でリンク）
     ↓
ローカル動作確認
     ↓
Squash and merge で main へ統合
     ↓
ブランチ削除
```

**例外なくこのフローを守る**。直接 main への push、Issue 無しの作業、PR 無しのマージは行わない。

### 2-2. ブランチ命名規則

| 種別 | パターン | 例 |
|---|---|---|
| 新機能 | `feature/#番号-説明` | `feature/#5-recipe-create` |
| バグ修正 | `fix/#番号-説明` | `fix/#15-save-bug` |
| ドキュメント | `docs/#番号-説明` | `docs/#3-readme-update` |
| 雑務 | `chore/#番号-説明` | `chore/#2-eslint` |

### 2-3. コミットメッセージ規則

Conventional Commits 形式・**日本語**：

```
種別: 変更の要約（50字以内）

詳細説明（任意）

Closes #(Issue番号)
```

種別: `feat` / `fix` / `docs` / `style` / `refactor` / `test` / `chore`

### 2-4. ラベル運用

| ラベル | 用途 |
|---|---|
| `enhancement` | 新機能・改善 |
| `bug` | バグ修正 |
| `documentation` | ドキュメント |
| `chore` | 設定・ツール |

すべての Issue・PR には必ずラベルを付ける。

---

## 3. 技術スタック

### 3-1. 採用技術と選定理由

| レイヤー | 採用技術 | 選定理由 |
|---|---|---|
| バックエンド | Ruby 3.x + Ruby on Rails 7.x（API モード） | 前プロジェクト（Java/Spring Boot）と異なる言語・FW で学習効果を最大化 |
| フロントエンド | Nuxt 3（Vue.js 3 ベース）+ Tailwind CSS | 前プロジェクト（React）と異なる FW で新規学習 |
| データベース | MySQL 8.x | 前プロジェクト（PostgreSQL）と異なる RDB |
| インフラ | AWS EC2 + RDS（無料枠） | デプロイ経験の継続学習 |
| IaC | Terraform | 前プロジェクトから継続採用 |
| コンテナ | Docker Compose（DB 用） | 同上 |

### 3-2. ポート番号

| サービス | ポート |
|---|---|
| Rails（バックエンド） | 3000 |
| Nuxt（フロントエンド） | 3001 |
| MySQL（DB） | 3306 |

ポート競合時は kill して正規ポートで起動する（別ポートでの代替起動は禁止）。

---

## 4. AI 利用方針

### 4-1. 透明性の確保

- 本リポジトリは **Claude Code を活用して開発**している
- コミットメッセージに `Co-Authored-By: Claude` を残している
- 設計判断・技術選定は AI と相談して進めるが、**最終判断は開発者が行う**

### 4-2. AI 利用の品質基準

- AI に書かせたコードは、**自分の言葉で説明できる状態**にしてからコミット
- 分からないコードは AI に「なぜこの書き方？」と質問
- AI の説明が公式ドキュメントとズレていたら、**公式が正しい**

---

## 5. 学習方針

### 5-1. トヨタ式 PDCA(S) サイクル

すべての作業に PDCAS を適用：

- **P** (計画): Issue 起票・受け入れ条件・リスク洗い出し
- **D** (実行): 安心・安全ファーストで実装、問題発見時は即停止（Jidoka）
- **C** (確認): コードレビュー・ビルド成功・動作確認
- **A** (処置): 5 Whys（なぜなぜ分析）で根本原因を特定
- **S** (標準化): 学んだ知見を docs/ に記録、次回以降に活用

詳細は `CLAUDE.md` セクション 16。

### 5-2. 安心・安全ファースト

作業完了後に必ず 3 ステップを実施：

1. **コードレビュー**: 変更ファイルの読み返し・外部識別子の事実検証
2. **チェックサム**: ビルド・テストがエラーなく完了
3. **ヘルスチェック**: ブラウザ・curl で実際に動作確認

詳細は `CLAUDE.md` セクション 17。

---

## 5-3. 機密情報の取り扱い

前プロジェクト（task-board）で **application.yml に DB パスワードを平文ハードコードして Public リポジトリに push** した不可逆事故が発生しました。
本リポジトリではその教訓を踏まえ、以下の多層防御を採用：

| 層 | 対策 |
|---|---|
| 1. テンプレート | `.env.example` で環境変数の枠組みを提供 |
| 2. 除外設定 | `.env` は `.gitignore` で Git 管理外 |
| 3. 自動スキャン | `.pre-commit-config.yaml` で gitleaks が機密情報を検知・ブロック |
| 4. 手動チェック | デプロイ前監査チェックリスト（CLAUDE.md セクション 15-3）|
| 5. ルール | コミットメッセージレビュー時に `.env` 等が含まれていないか確認 |

開発者は `brew install pre-commit gitleaks && pre-commit install` で hook を有効化してください。
**閲覧者は何もしなくて構いません**（読むだけなら影響しません）。

---

## 6. 禁止事項（Claude Code が守るべきルール）

| 種別 | 禁止内容 |
|---|---|
| Git 操作 | `git push origin main` 直接実行、`git push --force` を main に対して実行 |
| ワークフロー | Issue なしのブランチ作成、PR なしの main 反映 |
| 機密情報 | `.env` のコミット、パスワードのコード直書き |
| Terraform | `terraform destroy` / `terraform apply -auto-approve` の AI 単独実行 |
| AWS | `aws *delete*` / `aws *terminate*` の AI 単独実行 |
| 本番データ | DB / バックアップ削除操作の AI 単独完結 |

詳細は `CLAUDE.md` セクション 6 と 12。

---

## 7. リポジトリ構成

```
recipe-board/
├── README.md                   ← プロジェクト概要・セットアップ手順
├── OPERATIONS.md               ← 本ファイル（運用方針）
├── CLAUDE.md                   ← Claude Code 行動規範（詳細）
├── .gitignore
├── .github/
│   ├── ISSUE_TEMPLATE/         ← Issue テンプレート
│   └── pull_request_template.md ← PR テンプレート
├── docs/                       ← 設計ドキュメント
│   └── learning-notes.md       ← 開発中の学び・事故記録
├── docker-compose.yml          ← MySQL 起動（Phase 2 で追加）
├── backend/                    ← Rails アプリ（Phase 2 で追加）
└── frontend/                   ← Nuxt アプリ（Phase 2 で追加）
```

---

## 8. 開発フェーズ

| フェーズ | 内容 | 状態 |
|---|---|---|
| Phase 0 | リポジトリ初期化・運用ルール整備 | ✅ 完了 |
| Phase 1 | 設計ドキュメント（要件定義・画面設計・DB設計） | 進行中 |
| Phase 2 | バックエンド・フロントエンドの実装（CRUD） | 未着手 |
| Phase 3 | 機能拡張（タグ・検索・画像アップロード） | 未着手 |
| Phase 4 | AWS デプロイ（EC2 + RDS、無料枠） | 未着手 |

詳細な進捗は GitHub Issues / Project ボードで管理。

---

## 9. 緊急時リカバリー手順

将来の書き換えや誤操作で取り返しのつかない状態に陥った時の初動手順。
**起きてからではなく、起きる前に手順を読んでおくこと**。

### 9-1. 機密情報を誤って push した場合（🔴 最重要・不可逆）

**前提**: いったん公開リポジトリに push されると、Git 履歴・GitHub のキャッシュ・fork に残るため**完全削除は不可能**。

```bash
# ① 即座に該当 credentials を無効化（最優先）
#    - DB パスワードならデータベースで変更
#    - API キーなら発行元で revoke
#    - AWS キーなら IAM で deactivate

# ② Git 履歴から削除（fork 等で残る前提）
brew install git-filter-repo
git filter-repo --path <該当ファイル> --invert-paths
git push origin main --force-with-lease   # ※ enforce_admins を一時 false にする必要あり

# ③ 後始末
#    - incident-library に詳細記録
#    - .pre-commit-config.yaml と .gitignore で同種事故の予防強化
```

### 9-2. main が汚染された場合（誤コミット・revert したい）

```bash
# ① 該当コミットを特定
git -C /Users/macmini/Desktop/recipe-board log --oneline -10

# ② revert 用のブランチを作成
git -C /Users/macmini/Desktop/recipe-board checkout -b 'fix/#XX-revert-pollution'

# ③ revert コミット作成（force-push は禁止）
git -C /Users/macmini/Desktop/recipe-board revert <汚染コミット SHA>

# ④ push → PR → squash-merge
git -C /Users/macmini/Desktop/recipe-board push -u origin 'fix/#XX-revert-pollution'
gh pr create --title "fix: 汚染コミットを revert" ...
```

### 9-3. CLAUDE.md / .pre-commit-config.yaml / .gitignore が破損した場合

baseline タグから個別ファイル復元：

```bash
# ① 該当ファイルを baseline 時点に復元
git -C /Users/macmini/Desktop/recipe-board checkout baseline-2026-05-08 -- CLAUDE.md
# または
git -C /Users/macmini/Desktop/recipe-board checkout baseline-2026-05-08 -- .pre-commit-config.yaml
git -C /Users/macmini/Desktop/recipe-board checkout baseline-2026-05-08 -- .gitignore

# ② 復元コミットを branch + PR で main に反映
git -C /Users/macmini/Desktop/recipe-board checkout -b 'fix/#XX-restore-from-baseline'
git -C /Users/macmini/Desktop/recipe-board commit -m "fix: baseline-2026-05-08 から復元"
# → PR フローで main に反映
```

### 9-4. メモリが破損・消失した場合

dev-templates の memory-backup から復元：

```bash
# ① dev-templates が無ければクローン
cd ~/Desktop
git clone https://github.com/80-cloud/dev-templates.git _templates

# ② メモリディレクトリを復元
mkdir -p ~/.claude/projects/-Users-macmini-Desktop-Cursor/memory
cp ~/Desktop/_templates/memory-backup/*.md \
   ~/.claude/projects/-Users-macmini-Desktop-Cursor/memory/

# ③ Claude セッション再起動 → メモリが読まれることを確認
```

### 9-5. ブランチ保護が解除された場合

CLAUDE.md セクション 8 のコマンドで再設定：

```bash
gh api repos/80-cloud/recipe-board/branches/main/protection \
  --method PUT \
  --header "Accept: application/vnd.github+json" \
  --input - <<'EOF'
{
  "required_status_checks": null,
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 0
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

設定変更の経緯を Issue に記録すること。

### 9-6. dev-templates が誤って public になった場合

```bash
# ① 即 private に戻す
gh repo edit 80-cloud/dev-templates --visibility private --accept-visibility-change-consequences

# ② 公開期間中の影響評価
#    - Google Search Console でインデックス状況確認
#    - 公開されていた間に fork されていないか
#    - 含まれていた個人情報の有無確認
#    - 必要なら GitHub サポートにキャッシュ削除依頼
```

### 9-7. baseline タグの再作成が必要な場合

仕組みを大幅に再構築した後、新しい "good state" を baseline にする：

```bash
git -C /Users/macmini/Desktop/recipe-board tag -a baseline-YYYY-MM-DD -m "..."
git -C /Users/macmini/Desktop/recipe-board push origin baseline-YYYY-MM-DD

# 旧 baseline は削除せず保持（過去の良好な状態として参照可能）
```

### 9-8. baseline タグは「不変」— タグ保護の根拠

baseline タグは Repository Rules (rulesets) で **削除・更新・force-push が禁止** されている（CLAUDE.md セクション 8-2 参照）。

これにより以下が**できない**：
- `git push --delete origin baseline-2026-05-08`
- `git tag -f baseline-2026-05-08 <別の commit>` を push
- `git push --force origin baseline-2026-05-08`

意図的に baseline を更新する場合は、**新しい日付の tag を別名で作る**（旧 baseline は保持）。

> **過去事故（D-6）**: 当初、ブランチ保護がタグに適用されると誤解していた。Phase D テストで判明し、Repository Rules を追加して修正済。

---

## 10. 自己完結性について

**本リポジトリは外部の個人リソースに依存せず、単独で運用可能**。

開発者の手元 PC には全プロジェクト共通の学習リソース（横断学習システム）が併用されているが、
それは開発者個人の学習効率化のためのもので、本プロジェクトの動作・評価には影響しない。

リポジトリ閲覧者は、**本リポジトリ内のファイルだけ**を見れば、プロジェクト全体の運用方針を理解できる。

---

## 11. お問い合わせ

開発者: hideharu-AI（GitHub: [@80-cloud](https://github.com/80-cloud)）

このプロジェクトは個人の学習用です。スクール提出後の保守・サポートは行いません。
