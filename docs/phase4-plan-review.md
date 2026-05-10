# Phase 4 B-7 Plan Review

## メタ情報

| 項目 | 値 |
|---|---|
| 対象 plan | B-6 / `terraform plan -out` で生成、本 B-7 で再実行して再現性確認 |
| レビュー日 | 2026-05-10 |
| レビュー実施 | AI（Claude） + 人間（hideharu）二重チェック |
| AWS provider | v5.100.0（`.terraform.lock.hcl` で pin） |
| Terraform | v1.15.2 |
| **AI 最終判定** | **GO**（apply 着手可能・ただし下記人間チェック後） |

---

## 1. リソース内訳

### Plan summary

```
Plan: 6 to add, 0 to change, 0 to destroy.
```

### 6 リソースの主要属性

| address | type | 主要属性 |
|---|---|---|
| `aws_security_group.ec2` | SG | SSH 22 from 180.31.106.2/32 + ::1/128 / HTTP 80 from anywhere |
| `aws_security_group.rds` | SG | MySQL 3306 from EC2 SG only |
| `aws_db_subnet_group.main` | DB Subnet Group | default VPC subnets |
| `aws_db_instance.main` | RDS | MySQL 8.4 / db.t3.micro / 20GB gp3 encrypted / deletion_protection=true / publicly_accessible=false |
| `aws_instance.app` | EC2 | AL2023 (`ami-016b9681bbde99d74`) / t3.micro / IMDSv2 強制 / EBS 8GB gp3 encrypted / user_data attached |
| `aws_eip.app` | EIP | attached to `aws_instance.app` |

---

## 2. 無料枠コンプライアンス

| リソース | 無料枠条件 | 本 plan | 判定 |
|---|---|---|---|
| EC2 t3.micro | 750h/月 | 1 instance | ✅ |
| RDS db.t3.micro | 750h/月（独立予算） | 1 instance | ✅ |
| EBS gp2/gp3 | 30GB/月 | 8GB (EC2) + 20GB (RDS) = 28GB | ✅ |
| EIP | EC2 attached なら無料 | attached 状態 | ✅（停止時は $3.60/月） |
| Data transfer outbound | 100GB/月 | 想定内 | ✅ |
| RDS Snapshot | 20GB/月 | retention=0 で課金回避 | ✅ |
| VPC / SG / Subnet | 常時無料 | default VPC 流用 | ✅ |

**推定月額: $0**（条件付き：EC2 + RDS 常時起動 / EIP detach なし）

⚠️ EIP detach 時 $3.60/月（incident `2026-05-09-eip-stopped-ec2-charge`）。EC2 を停止する運用は GitHub Actions の RDS auto-stop と同様の専用ワークフローを別途整備（PR #61 で task-board に実装済）。

---

## 3. セキュリティレビュー

| 項目 | 値 | 評価 |
|---|---|---|
| EC2 SSH source IPv4 | 180.31.106.2/32 | ✅ 単一 IP 限定 |
| EC2 SSH source IPv6 | ::1/128 (loopback) | ✅ 実質無効化 |
| EC2 HTTP source | 0.0.0.0/0 + ::/0 | 🟡 学習用全開放（HTTPS 化は B-9 以降） |
| EC2 IMDSv2 強制 | http_tokens=required | ✅ |
| EC2 EBS 暗号化 | true | ✅ |
| EC2 EBS delete_on_termination | true | 🟡 replace で root vol 失う（B-9 で再考） |
| RDS publicly_accessible | false | ✅ |
| RDS storage_encrypted | true | ✅ |
| RDS deletion_protection | true | ✅ 二重ロック（Terraform `prevent_destroy` + AWS 側） |
| RDS backup_retention_period | 0 | 🟡 バックアップなし（学習用許容・本番 NG） |
| db_password 流路 | tfvars (gitignored) → tfstate (gitignored 予定) | ✅ git に commit されない |
| user_data 機密 | EC2 metadata から閲覧可能 | ✅ 機密リテラルなし（PR #80 / #82 検証済） |
| tfstate（apply 後生成） | `*.tfstate*` で gitignore 済 | ✅ 予防済 |

---

## 4. 過去事故突合（incident-library 全件）

| 事故 | 突合結果 |
|---|---|
| 2026-05-07-curl-minimal-conflict | ✅ user_data.sh で curl install せず |
| 2026-05-07-t3micro-oom | ✅ user_data.sh で swap 2GB（PR #80） |
| 2026-05-07-java-version-mismatch | ✅ Ruby/Node を user_data.sh に含めず |
| 2026-05-07-hardcoded-password | ✅ db_password は tfvars 経由（gitignored） |
| 2026-05-07-cors-rejected-ec2-ip | N/A 後続フェーズの CORS 設定で対応 |
| 2026-05-08-gitleaks-low-entropy-gap | ✅ db_password は openssl rand 生成 32 文字 |
| 2026-05-08-cross-repo-cwd-mistake-recurrence (1〜4 連) | ✅ feedback_cd_prefix_mandatory 適用、B-7 中も cwd 事故ゼロ |
| 2026-05-08-premature-critical-declaration | ✅ JSON 属性を 1 件ずつ verify（feedback_static_analysis_blindspot） |
| 2026-05-08-branch-protection-admin-bypass | N/A プロセス事故・本 plan に関連せず |
| 2026-05-09-eip-stopped-ec2-charge | 🟡 attached 状態は無料、運用ガイドライン要 |
| 2026-05-09-tokyo-region-t2micro-not-free | ✅ t3.micro 採用 |
| 2026-05-09-insider-threat-meta-finding | ✅ scout-drone v3.4 で対応検討中 |
| 2026-05-10-cwd-4th-recurrence | ✅ feedback_cd_prefix_mandatory で予防 |
| 2026-05-10-premature-zero-claim | ✅ 本レビューで「ゼロ」を疑い属性 verify 実施 |

---

## 5. ブラスト半径 / 可逆性

| 項目 | 評価 |
|---|---|
| apply 失敗時の影響 | Terraform は失敗 resource 以降を中断、既存 resource は触らない |
| 既存 AWS リソースへの影響 | task-board の停止中 EC2 / RDS は **触らない**（命名・タグで完全分離） |
| 全 destroy 可能性 | RDS の `prevent_destroy` + `deletion_protection` を両方手動解除すれば可能 |
| 部分 rollback | `terraform destroy -target=...` で個別削除可（依存順序に注意） |
| state 巻き戻し | tfstate ローカル管理 / 手動コピーでバックアップ |
| **隔離性** | recipe-board 名前空間に隔離・他プロジェクトに波及せず |

---

## 6. クロスレイヤー整合（incident `java-version-mismatch` 系）

| 観点 | 確認結果 |
|---|---|
| AMI ↔ user_data.sh | AL2023 ↔ user_data.sh は AL2023 仕様準拠（dnf / curl-minimal 配慮済） |
| EC2 SG ↔ RDS SG | RDS SG は EC2 SG を許可元として参照、順序整合 OK |
| EIP ↔ EC2 | EIP は EC2 に attach、`replace_on_change=true` で IP 保持 |
| DB credentials ↔ アプリ | 後続フェーズ B-9 で Rails への受け渡し方法を決定要 |
| user_data SHA hash ↔ 実体 | Terraform は plan で SHA1 hash 表示（`58297a3...`）、apply 時は `file()` 実体を AWS にアップロード |

---

## 7. tfstate 取扱（apply 後生成）

| 項目 | 状態 |
|---|---|
| 生成タイミング | B-8 apply 直後に `infra/terraform.tfstate` 生成 |
| 含まれる機密 | db_password / EC2 instance ID / RDS endpoint 等 |
| gitignore | ✅ `*.tfstate*`（`infra/.gitignore` line 23） |
| backup ファイル | `terraform.tfstate.backup` も gitignore 済 |
| バックアップ運用 | 学習用は手動コピーで十分 / リモートバックエンドは Phase 5 検討 |

---

## 8. 未検証項目（B-8 apply で初めて分かる）

| 項目 | リスク度 |
|---|---|
| user_data.sh の cloud-init 実行成否 | 低（shellcheck + dnf retry 実装済） |
| nginx default docroot が `/usr/share/nginx/html/` であること | 中（PR #80 review で flag 済 / curl で apply 後検証） |
| EIP attach 時の API 動作 | 低（Terraform 標準フロー） |
| RDS 起動時間 5-10 分（apply タイムアウト要確認） | 低 |
| EC2 → RDS 接続性 | 中（SG 設定済だが実機 ping/mysql client での確認 = B-9 以降） |

---

## 9. AI 最終判定

**GO**（apply 着手可能）

理由:
- 全 8 軸でブロッカーなし
- 🟡 軽い気づき 4 件は学習用として許容範囲（本番化時の TODO リストに転換）
- ブラスト半径が recipe-board 名前空間に隔離
- 復旧コストが低い（free tier / 部分 destroy 可能）
- 修練城のチェックゲート（プロセス + 多重防御 + 過去事故突合）が機能中

---

## 10. 人間レビューチェックリスト（hideharu さん向け）

apply 前に以下を本人の目で確認してください:

### コード理解
- [ ] `infra/main.tf` の 6 リソース定義を読んで、各々が何をするか説明できる
- [ ] `infra/user_data.sh` を読んで、初回 boot で何が起きるか説明できる
- [ ] `infra/terraform.tfvars` の 5 値が自分の意図通りの値になっている
- [ ] EC2 SG ingress の SSH source IPv4 が **現在の自分の IP** と一致（`curl -4 https://checkip.amazonaws.com` で再確認）

### コスト理解
- [ ] EC2 + RDS は free tier 750h/月 制限を理解している
- [ ] EIP は EC2 起動中は無料、停止すると $3.60/月かかることを理解している
- [ ] 不要時は `terraform destroy` で削除する運用を理解している（`prevent_destroy` 解除手順含む）

### 緊急時対応
- [ ] AWS Console で手動 EC2 停止 / RDS 停止の操作を知っている
- [ ] AWS Budgets `Recipe-Board-Early-Warning` ($0.5) と `Zero-Spend` ($1.0) のアラート受信先を確認済
- [ ] 万一の課金事故時、AWS サポートに連絡する手順を知っている

### 修練城ルール
- [ ] B-8 apply は **明示承認後** に実行する旨を認識している（`terraform apply -auto-approve` は deny ルール + D-DESTRUCT-REGEX で阻止される）

---

## 後続フェーズ

- **B-8**: `terraform apply`（明示承認後・修練城ルール準拠）
- **B-9 以降**: アプリ deploy（Ruby / Rails / MySQL client / Nginx reverse proxy）
