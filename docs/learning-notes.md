# 学習ノート (Learning Notes)

> CLAUDE.md セクション 16-6 のルールに従い、作業の学びを継続的に記録する。
> 標準化（PDCA の S）の蓄積場所として運用する。

---

## 2026-05-08: GitHub アカウント名の誤認事故（プロジェクト初期セットアップ時）

### 何をしたか

プロジェクト初期セットアップ中、GitHub リポジトリの URL を CLAUDE.md / README.md に記載する際、
ローカルの git config の `user.name`（hideharu-AI）を GitHub アカウント名と誤認した。

### つまずいた点

- CLAUDE.md と README.md の合計 5 箇所に `hideharu-AI/recipe-board` という URL を記載してしまった
- 実際の GitHub アカウント名は `80-cloud`（`gh api user --jq '.login'` で確認）
- 誤った URL のままコミット（`9b08e0f chore: プロジェクト初期化`）してから誤りに気づいた

### 発覚プロセス

push 直前に `gh auth status` で認証状態を確認した際、`80-cloud` で認証されていた。
Claude が「認証アカウントと記載した URL の owner が違う」ことに気づいて、ユーザーに報告。
`gh api user` で実アカウント名を確認して事実が確定した。

→ **「実行こそ真実」が機能した好例**。会話・推測ではなく、実コマンドで真偽を確定させた。

### 5 Whys（なぜなぜ分析）

| 段階 | 内容 |
|---|---|
| なぜ 1 | Claude が `hideharu-AI` を GitHub アカウント名と仮定した |
| なぜ 2 | ローカル git の `user.name` を確認したが、それが GitHub と同じだと思い込んだ |
| なぜ 3 | GitHub 認証情報を最初に確認するステップを省略した |
| なぜ 4 | 「個人アカウント vs 組織」の会話の流れで、検証より推測を優先した |
| なぜ 5 | 新規プロジェクト開始時の事前検証ルール（Pre-flight Check）が未確立だった |

→ **真因**：新規プロジェクト開始時の Pre-flight Check 体系の不在。

### 修正内容

- 修正方法は「amend」ではなく「追加コミット」を選択（履歴を残すため）
- 追加コミット: `53e32ed docs: GitHub リポジトリURLを 80-cloud/recipe-board に修正`
- 修正範囲: README.md (1箇所) / CLAUDE.md (4箇所) → 計 5 箇所

### 標準化（S = Standardize）— 4 層の再発防止策

| 層 | 対策 | 配置場所 | 状態 |
|---|---|---|---|
| 1 | Claude のメモリに「新規プロジェクト時は `gh api user` を最初に実行」を保存 | `~/.claude/projects/-Users-macmini-Desktop-Cursor/memory/feedback_new_project_preflight.md` | ✅ 実装済 |
| 2 | 共通リファレンスとして Pre-flight Check リストを作成 | `/Users/macmini/Desktop/_templates/new-project-preflight-check.md` | ✅ 実装済 |
| 3 | 本プロジェクトに事故全プロセスを記録（このファイル） | `docs/learning-notes.md` | ✅ 実装済 |
| 4 | ユーザー側ルール: 新規プロジェクト時に「アカウント名確認した？」を最初に確認 | 記憶・習慣 | 運用中 |

### 横展開できそうなこと

- ローカル設定値（git config / npm config / aws config 等）と外部サービスのアカウント名は別物として扱う
- 「思い込み」より「実行コマンドでの検証」を優先する（特に固有名詞）
- 重要な固有名詞（URL / アカウント名 / リソース名）は記載前後に `grep -rn` で一貫性を確認する
- 残り 19 アプリの開発でも同様のチェックを適用すれば、同じ事故は防げる

### 教訓（カイゼン）

> 「動いた」「合ってそう」で進めず、**実コマンドで真偽を確定させる**。
> 推測で書いたコードや URL は、**書いた瞬間に grep / 実行で裏取り**する習慣をつける。
