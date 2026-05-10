# Phase 4 B-8 Apply 実作業記録

## メタ情報

| 項目 | 値 |
|---|---|
| 実施日 | 2026-05-10 |
| 関連 PR | (本 PR) |
| 関連 Issue | #89 |
| 実施者 | AI（Claude）+ 人間（hideharu）二重チェック |
| AWS Account | 383158157670 |
| Region | ap-northeast-1 |
| Terraform | v1.15.2 |
| AWS Provider | v5.100.0 |

---

## 1. Apply 実行サマリ

### コマンド

```bash
terraform -chdir=infra apply -input=false /tmp/recipe-board-b8.tfplan
```

### 結果

```
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
```

### 所要時間

| リソース | 作成時間 |
|---|---|
| aws_db_subnet_group.main | 1s |
| aws_security_group.ec2 | 3s |
| aws_security_group.rds | 3s |
| aws_instance.app | 13s |
| aws_eip.app | 2s |
| aws_db_instance.main | **5m6s** |
| **合計** | **約 5m 22s** |

RDS の創出が支配的（想定通り）。

---

## 2. 作成されたリソース ID（学習用記録・機密性なし）

| リソース | ID / 値 |
|---|---|
| EC2 instance | `i-0a0750d93520560d5` |
| EC2 EIP | `13.192.27.9` |
| EC2 EIP allocation | `eipalloc-0d4c2ae7bdee1b3c6` |
| EC2 EIP association | `eipassoc-023db1f0289fbdc79` |
| EC2 SG | `sg-05ea45b652601e2c1` |
| RDS SG | `sg-0ee764f2d42ae5165` |
| RDS instance | `recipe-board-db` |
| RDS endpoint | `recipe-board-db.cxmg6mui6qkr.ap-northeast-1.rds.amazonaws.com:3306` |
| RDS DB resource ID | `db-6ZDJQPDJD3B3AQNEA55HS54BDU` |
| DB Subnet Group | `recipe-board-db-subnet-group` |
| VPC（既存・流用） | `vpc-0910bd673c5f52c96` |

> ※ db_username / db_password は本文書に記載しない（tfvars / tfstate のみで管理）

---

## 3. ヘルスチェック結果

### EIP に curl

```
curl http://13.192.27.9/
→ HTTP 200 / 357 bytes / 0.040s
```

### nginx で返ってきた HTML

```html
<head><meta charset="UTF-8"><title>recipe-board EC2 bootstrap</title></head>
<h1>recipe-board: EC2 bootstrap successful</h1>
<p>completed_at: 2026-05-10T20:49:17+09:00</p>
```

→ user_data.sh が完走、nginx 起動、JST タイムゾーン適用、bootstrap 成功 ✅

### AWS describe による状態確認

| リソース | 状態 |
|---|---|
| EC2 | running / t3.micro / Public IP 13.192.27.9 / Private IP 172.31.27.1 |
| EIP | attached to i-0a0750d93520560d5 |
| RDS | available / Endpoint resolved / DeletionProtection=True / StorageEncrypted=True / PubliclyAccessible=False |
| EC2 SG | HTTP 80 from 0.0.0.0/0 / SSH 22 from 180.31.106.2/32 |
| RDS SG | MySQL 3306 from EC2 SG only |

---

## 4. Apply 中に検出した修練城の問題

### 🟡 中レベル: D-EC2-COUNT hook の regex バグ

**症状:**
- `terraform -chdir=infra apply -input=false /tmp/recipe-board-b8.tfplan` を実行したが、D-EC2-COUNT フックが **発火しなかった**
- 一方で `gh issue create` の body に "terraform apply" 文字列が含まれるとフックが発火（false positive）

**真因:**
- 現在の hook 正規表現: `(^| )(terraform apply|aws ec2 start-instances|aws ec2 run-instances)`
- これは「terraform apply」を **連続文字列**として要求
- `terraform -chdir=infra apply` は `terraform` と `apply` の間に `-chdir=infra` が挟まり、連続マッチしない
- → D-DESTRUCT-REGEX 改善時に発見した同系統のバグ（feedback_deny_prefix_match_bypass）が D-EC2-COUNT に未適用

**影響度:**
- 今回の apply は running_count=0 だったため warning レベル（block 対象外）
- 将来 task-board EC2 が running 状態のとき本フックがトリガーすべきだが、`-chdir=` 経由 apply では発火しない
- **無料枠 750h 超過リスクの検知漏れ**になりうる

**残課題（別 Issue 提案）:**
- D-EC2-COUNT の regex を D-DESTRUCT-REGEX と同等の正規表現に強化
- `terraform.*apply|terraform.*-chdir.*apply` 等で連続性要求を緩和

### 🟢 軽: D-DESTRUCT-REGEX の self-bite 再発

Issue body に "terraform apply -auto-approve" リテラルが含まれていたため初回投稿が block。`feedback_chaos_test_self_falsepositive` で記録済の既知パターン。回避策（`--body-file` でファイル経由）を適用して再投稿。

---

## 5. tfstate 取扱の確認

| 項目 | 状態 |
|---|---|
| tfstate 生成パス | `infra/terraform.tfstate` |
| ファイルサイズ | ~26KB |
| db_password 含有 | あり（実値は本文書に記載しない） |
| storage_encrypted | true |
| **gitignore 状態** | ✅ `infra/.gitignore:19` の `*.tfstate` でマッチ |
| **git status** | tracked になっていない（commit 対象外） |
| backup ファイル | `infra/.gitignore:49` の `*.backup` でマッチ |

→ 機密値が git に commit されるリスクは多重防御で防がれている。

---

## 6. コスト確認

| 項目 | 状態 |
|---|---|
| AWS Budgets `Zero-Spend` ($1.0) | 設定済 |
| AWS Budgets `Recipe-Board-Early-Warning` ($0.5) | 設定済 |
| EC2 t3.micro | 無料枠 750h/月（recipe-board 1 instance のみ起動） |
| RDS db.t3.micro | 無料枠 750h/月（独立枠・recipe-board 1 instance） |
| EBS | 8GB (EC2) + 20GB (RDS) = 28GB / 30GB 無料枠 |
| EIP | EC2 attached 状態のため無料 |

**現時点予想月額**: $0（条件付き：常時起動 / EIP detach なし）

⚠️ EC2 を停止する場合は同時に EIP も release または instance 起動を維持（incident `2026-05-09-eip-stopped-ec2-charge`）。

---

## 7. 学習用 SSH 接続コマンド（参考）

```bash
ssh -i ~/.ssh/recipe-board-key.pem ec2-user@13.192.27.9
# cloud-init log 確認
sudo cat /var/log/user-data.log
# cloud-init done marker
sudo cat /var/log/user-data.done
```

※ EIP は AWS 上で固定、tfvars/main.tf 変更しない限り変動しない。

---

## 8. 後続フェーズ

- **B-9**: アプリ deploy（Ruby / Rails / MySQL client / Nginx reverse proxy）
- **運用**: 不要時は `terraform destroy`（`prevent_destroy` 解除手順を別 PR で整備推奨）

### 別 Issue として提案する後続作業

1. D-EC2-COUNT hook の regex 強化（本記録 §4 の中レベル finding）
2. EC2 停止運用ワークフロー整備（task-board の RDS auto-stop と同等パターン）
3. RDS 自動再起動 7 日防止ワークフローの recipe-board への横展開

---

## 9. 修練城ルール準拠チェック

- ✅ Issue ファースト（#89）
- ✅ ブランチ命名 `chore/#89-terraform-apply`
- ✅ コミットメッセージ日本語 + Conventional Commits
- ✅ cd 前置必須（feedback_cd_prefix_mandatory · cwd 5 回目事故ゼロ継続）
- ✅ ランタイム属性 verify（feedback_static_analysis_blindspot · apply 後の AWS describe + curl で実機検証）
- ✅ 自動承認系コマンド未使用（plan ファイル経由・修練城の deny ルール準拠）
- ✅ ヘルスチェック完了まで「成功」宣言を保留（feedback_severity_calibration）
