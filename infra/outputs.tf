# ============================================
# recipe-board / infra / outputs.tf — Phase 4 B-5-δ
# ============================================
# B-7 plan レビューおよび B-6 以降のデプロイ後確認で使う出力値。
#
# 機密値の取り扱い（D-INFRA-OUTPUTS-1 の審査結果）:
#   - db_password: 出力しない（tfstate には残るが、stdout / output には出さない）
#   - home_ipv*_cidr: 出力しない（個人情報）
#   - DB endpoint: ホスト名のみ・資格情報を含まない → 公開可
# ============================================

# ----- ネットワーク（参照用）-----
output "vpc_id" {
  description = "流用しているデフォルト VPC の ID"
  value       = data.aws_vpc.default.id
}

# ----- EC2 -----
output "ec2_instance_id" {
  description = "EC2 インスタンス ID"
  value       = aws_instance.app.id
}

output "ec2_public_ip_initial" {
  description = "EC2 起動時に AWS が割当てるパブリック IP（EIP アタッチ後は EIP の値を使うこと）"
  value       = aws_instance.app.public_ip
}

# ----- EIP（運用上の正規アクセス IP）-----
output "eip_public_ip" {
  description = "Elastic IP（SSH / HTTP の接続先・運用上の正規 IP）"
  value       = aws_eip.app.public_ip
}

# ----- RDS -----
output "rds_endpoint" {
  description = "RDS エンドポイント（host:port）"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "RDS ホスト名のみ"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "RDS ポート"
  value       = aws_db_instance.main.port
}
