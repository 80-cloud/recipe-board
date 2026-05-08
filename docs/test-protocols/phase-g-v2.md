# Phase G v2 — CRUD 着手前 / デプロイ前 / 提出前の必須チェックリスト

> Phase G v1（初代）では「重大発見 0」と結論したが、その**テスト手順自体**に
> 複数の盲点があり、後の混沌テスト（2026-05-08）で 1 件の重大事故（N-1）と
> 4 件の中程度発見が露見した。
>
> 本ドキュメントはその反省を反映した v2 プロトコル。
> **「個人を責めず仕組みを直す」原則**に従い、テスト手順自体を継続更新する。

---

## なぜ v2 が必要だったか

| Phase G v1 の盲点 | 結果 |
|---|---|
| ワークフローファイルの「設置場所」を検査していない（中身だけ見た）| R-1: backend/.github/workflows/ci.yml が一切実行されず |
| `required_status_checks` を確認していない | R-2: 保護有効=OK で早合点 |
| `.env.example` ↔ Rails コードの**片方向検査のみ** | R-3 / R-4: 双方向 diff していなかった |
| 値の整合性を確認していない（キーの存在のみ）| **N-1: 自分が作った PR で値が画面設計書と乖離** |
| allowlist の `regexTarget` 意味を検証していない | R-7: コメントアウト secret 素通り |
| ENV 変数が「コードで実際に参照されているか」を確認していない | R-5: dead ENV 残存 |

---

## v2 必須チェックリスト

### A. CI ワークフロー検証

- [ ] `gh api repos/.../actions/workflows` でアクティブな workflow を列挙し、想定数と一致するか
- [ ] workflow ファイルがすべて `.github/workflows/` 直下にあるか
- [ ] `gh api repos/.../branches/main/protection` で `required_status_checks` の中身を確認
- [ ] 各 required check が実際に PR でブロッキングするか（テスト PR で検証）
- [ ] Backend / Frontend / 機密スキャンの**3 本立て**（片肺になっていないか）

### B. 環境変数整合性（双方向 + 値整合）

- [ ] `grep` で抽出した Rails ENV キーと `.env.example` を **双方向 diff**
- [ ] `.env` と `.env.example` のキー集合を **双方向 diff**
- [ ] **値の整合性**: `.env.example` / `.env` / `nuxt.config.ts` のフォールバック値が一致
- [ ] **仕様との整合**: 画面設計書 / DB 設計書に書かれた API パス・URL と `.env.example` の値が整合
- [ ] dead ENV（`.env.example` にあるがコードで参照無し）を検出
- [ ] frontend (`nuxt.config.ts`) の `process.env.*` も同様にチェック

### C. セキュリティ設定の動作検証

- [ ] gitleaks allowlist の `regexTarget` を確認し、意図通りか検証
- [ ] テストパターン（コメント内 secret / 本番コード内 secret / テストファイル内 secret）で **実動作**を確認
- [ ] gitleaks ライブ実行（`gitleaks detect --no-git`）でノイズ件数を把握
- [ ] docker-compose のフォールバック値が低エントロピー（弱パス）になっていないか grep
- [ ] `lifecycle.prevent_destroy` 設定の存在確認（infra/ がある場合）

### D. クロスレイヤー整合性

- [ ] Ruby バージョン: `.ruby-version` / `Gemfile` / `Gemfile.lock` / CI 設定が**全て同じ値**
- [ ] Node バージョン: `.nvmrc` / `package.json` の `engines` / CI 設定が**全て同じ値**
- [ ] CORS 許可オリジンが ENV 駆動（ハードコードしていない）
- [ ] Vite/Nuxt dev port と Rails CORS_ALLOWED_ORIGINS が一致
- [ ] README に記載のセットアップ手順を**実際にトレース**して動くか確認

### E. メタチェック（テスト自体の正しさ検証）

- [ ] 「Phase G で 0 件」を**書く前に**、メタテストとして上記 A-D を再走査
- [ ] テスト項目が増えた場合は本ドキュメントを更新（テスト手順自体の進化を担保）
- [ ] 過去事故ライブラリ（`task-board/docs/incidents/`, `_templates/incident-library/`）を**最初に開く**
- [ ] 過去事故と同型のリスクが本プロジェクトに無いか網羅照合

---

## 自動化スクリプト

`scripts/preflight-check.sh` で以下を一括実行可能：

```bash
bash scripts/preflight-check.sh
```

カバー範囲：
- A: workflow 設置場所検査
- B: Rails ENV.fetch ↔ .env.example 双方向 diff
- B: API base 値の三点整合（.env.example / nuxt.config / 画面設計書）
- B: dead ENV 検出
- C: docker-compose 弱パスフォールバック検出（R-6 同型）

カバー範囲外（手動チェック必須）：
- D の Ruby / Node 全層整合
- E のメタチェック・過去事故ライブラリ突合

---

## 実行タイミング

| タイミング | 必須項目 |
|---|---|
| **PR 提出前**（コード変更時）| `bash scripts/preflight-check.sh` で ERRORS 0 を確認 |
| **CRUD 着手前** | A〜E すべて手動 + スクリプト実行 |
| **Phase 4 デプロイ前** | A〜E すべて + デプロイ前監査チェックリスト（CLAUDE.md セクション 15-3） |
| **講師提出前** | A〜E すべて + README どおりのセットアップを別ディレクトリで実トレース |

---

## 過去発見の追跡

本プロトコルが実際に発見した事故と、その incident-library への記録：

| ID | 内容 | 検出日 | 記録 |
|---|---|---|---|
| R-1 | backend/.github/workflows/ci.yml が認識されず | 2026-05-08 | （recipe-board PR #32 で修正） |
| R-2 | required_status_checks 未設定 | 2026-05-08 | Issue #27（人間承認待ち）|
| R-3/R-4 | ENV 整合性ギャップ | 2026-05-08 | recipe-board PR #33 で修正 |
| R-5 | dead ENV `RAILS_HOSTS` | 2026-05-08 | Issue #30 |
| R-6 | docker-compose 弱パスフォールバック | 2026-05-08 | Issue #30 |
| R-7 | gitleaks allowlist 未 paths 化 | 2026-05-08 | Issue #29 |
| R-8 | git author 表記揺れ | 2026-05-08 | Issue #30 |
| **N-1** | **`.env.example` の API base 値が画面設計書と乖離（自分の修正で発生）** | 2026-05-08 | [`_templates/incident-library/2026-05-08-env-example-value-drift.md`](../../../_templates/incident-library/2026-05-08-env-example-value-drift.md) |
| N-2 | Ruby バージョン全層強制不在 | 2026-05-08 | Phase 4 デプロイ前対応予定 |
| N-3 | Node バージョン全層強制不在 | 2026-05-08 | recipe-board PR #37 で修正 |
| N-4 | Frontend CI 不在 | 2026-05-08 | recipe-board PR #39 で修正 |

---

## 形骸化防止

本プロトコル自体も形骸化しうる。`_templates/anti-formality-mechanism.md` の
原則を適用して継続更新：

- **原則 1**: 新ルール追加時は過去事故サンプルで機能検証
- **原則 2**: 各チェック項目の最終適用日を PR / 振り返りで記録
- **原則 3**: B/C 振り返りで本プロトコルを必ず監査
- **原則 5**: 「該当しなかった」「適用したが効かなかった」を記録

→ 「pass = 安全」ではなく「**何を見逃しているか**」を意識する。

---

## 改訂履歴

| 版 | 日付 | 主な変更 |
|---|---|---|
| v1 | 2026-05-08（初代）| 初版（後のテストで複数の盲点が判明）|
| v2 | 2026-05-08 | A〜E の 5 軸に再構成。**値整合性** と **メタチェック** を追加。`preflight-check.sh` 自動化スクリプト連動 |
