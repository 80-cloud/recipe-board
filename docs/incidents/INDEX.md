# recipe-board Incident Index — プロジェクト独立版（修練城整備 #7）

> recipe-board に直接関連する incident の独立 INDEX。
>
> **横展開原本** = `_templates/incident-library/INDEX.md`（全プロジェクト横断）
> **本ファイル** = recipe-board に直接関連するもののみ
> **詳細 .md は重複させず** `_templates/incident-library/` 側を参照
>
> このファイルは task-board / 他プロジェクトと **独立**しているため、cross-repo 参照の脆弱性（task-board 削除時の link 切れ）を排除する目的で 2026-05-10 修練城整備 #7 で新設。

---

## 使い方

1. **症状をキーワードで `grep`** → 関連 incident 行を発見
2. **詳細リンク**で `_templates/incident-library/<日付>-<タイトル>.md` を開く
3. 過去事故突合は scout-drone-protocol v3.5 Phase 1-D の手順で実施

---

## 事故一覧（recipe-board 由来 / recipe-board 関連の誤投下）

| 日付 | カテゴリ | 症状 | 真因 | 詳細 |
|---|---|---|---|---|
| 2026-05-08 | 識別子誤認 | GitHub URL を 5 ファイルに誤記 | ローカル設定値を外部サービス値と混同、事前検証なし | [_templates](../../../_templates/incident-library/2026-05-08-github-account-confusion.md) |
| 2026-05-08 | 仕組み盲点 | ブランチ保護のテスト push が「管理者バイパス」で通った | enforce_admins: false が学習プロジェクトでは緩すぎた | [_templates](../../../_templates/incident-library/2026-05-08-branch-protection-admin-bypass.md) |
| 2026-05-08 | env-example 値ドリフト | env.example と main.tf の値書式が不整合 | 各値の書式を検証する手順がなかった | [_templates](../../../_templates/incident-library/2026-05-08-env-example-value-drift.md) |
| 2026-05-08 | 仕組み盲点 | gitleaks が低エントロピー secret 検知できず | 過去事故をテストケースに含めず「機能の確認」止まり | [_templates](../../../_templates/incident-library/2026-05-08-gitleaks-low-entropy-gap.md) |
| 2026-05-08 | 誤報・拙速エスカレーション | テストスクリプトのバグを「重大」と誤報・撤回不十分 | テスト自体の正しさを検証する習慣（メタテスト）不在 | [_templates](../../../_templates/incident-library/2026-05-08-premature-critical-declaration.md) |
| 2026-05-08 | 操作ミス（誤爆: task-board）| recipe-board の cleanup commit が task-board の main に着地 | Bash セッション間で cwd が引き継がれず、cd 後の次コマンドで cd 抜けた | [_templates](../../../_templates/incident-library/2026-05-08-cross-repo-cwd-mistake.md) |
| 2026-05-09 | 操作ミス（2 回目再発）| `gh issue create` が task-board に Issue を誤投下 | 2026-05-08 の cwd 引き継ぎ事故への対策が gh コマンドに未適用 | [_templates](../../../_templates/incident-library/2026-05-09-cross-repo-cwd-mistake-recurrence.md) |
| 2026-05-09 | 操作ミス（3 回目再発）| 1 セッション内で cwd 違反 4 件連続発生 | gh は仕組み化したが git コマンドに汎化されず（class vs instance の抽象化漏れ） | [_templates](../../../_templates/incident-library/2026-05-09-cwd-branch-state-3rd-recurrence.md) |
| 2026-05-09 | UI 奇襲（X-01 光学迷彩）| Nuxt DevTools で hydration エラーが SSR curl では見えない | 「SSR curl 通過 ≠ ブラウザ hydration 通過」を仕組みに刻めていなかった | [_templates](../../../_templates/incident-library/2026-05-09-nuxt-devtools-vue-router-hydration.md) |
| 2026-05-09 | UI 奇襲（X-02 キャッシュ）| mutation 後の別画面遷移で古いキャッシュ表示 | useFetch 等のクライアントキャッシュ無効化を仕組みに刻めていなかった | [_templates](../../../_templates/incident-library/2026-05-09-usefetch-cache-invalidation-after-mutation.md) |
| 2026-05-09 | AWS 課金 / リージョン差分（仮想）| 東京リージョンで t2.micro を選ぶと無料枠対象外で課金 | AWS 無料枠のリージョン依存性を理解していなかった（着手前 scout-drone で予防） | [_templates](../../../_templates/incident-library/2026-05-09-tokyo-region-t2micro-not-free.md) |
| 2026-05-09 | 仕組み盲点（メタ）| 内通者リスク 6 シナリオ（acceptEdits / Hook 改ざん / memory 汚染等） | 「衛兵を見張る衛兵」設計が組み込まれていなかった | [_templates](../../../_templates/incident-library/2026-05-09-insider-threat-meta-finding.md) |
| 2026-05-10 | 操作ミス（4 回目再発）| F1 fix の `git checkout -b` が Cursor (task-board) で実行 | 3 回目対策が instance ベース（pwd 確認）にとどまり class 抽象化（cd 前置必須）に昇格していなかった | [_templates](../../../_templates/incident-library/2026-05-10-cwd-branch-state-4th-recurrence.md) |

> 任意の incident を新規記録する場合: `_templates/incident-library/YYYY-MM-DD-<title>.md` に詳細を作成し、本 INDEX に行追加。

---

## カテゴリ別集計（recipe-board 関連のみ）

| カテゴリ | 件数 |
|---|---|
| 操作ミス（cwd / branch state）| 4（4 回再発済み・class 抽象化で解消） |
| 仕組み盲点 | 3 |
| UI 奇襲 | 2 |
| 誤報・拙速エスカレーション | 1 |
| 識別子誤認 | 1 |
| env-example 値ドリフト | 1 |
| AWS 課金 / リージョン差分 | 1 |

---

## 関連 protocol / memory

- scout-drone-protocol v3.5（Phase 1-D 過去事故突合）
- `feedback_incident_library`（症状/兆候/真因の 3 段階照合）
- `feedback_cd_prefix_mandatory`（cwd 4 連事故の class 抽象化）
- `_templates/incident-library/INDEX.md`（横展開原本）
