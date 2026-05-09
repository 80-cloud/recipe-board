# ============================================
# recipe-board / infra / variables.tf — Phase 4 B-5-δ
# ============================================
# main.tf に inline 宣言していた variable ブロックを集約。
# 値は terraform.tfvars に定義し、リポジトリには含めない（infra/.gitignore で除外）。
# 雛形は terraform.tfvars.example を参照。
# ============================================

# ----- リージョン / プロジェクト識別 -----
variable "aws_region" {
  description = "AWS リージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "リソース名 prefix / タグ用"
  type        = string
  default     = "recipe-board"
}

# ----- 自宅 IP（SSH 許可元）-----
variable "home_ipv4_cidr" {
  description = "自宅 IPv4 CIDR（SSH 許可元、書式: x.x.x.x/32）"
  type        = string
  sensitive   = true
}

variable "home_ipv6_cidr" {
  description = "自宅 IPv6 CIDR（SSH 許可元、書式: xxxx:xxxx::/64）"
  type        = string
  sensitive   = true
}

# ----- EC2 -----
variable "ec2_instance_type" {
  description = "EC2 インスタンスタイプ（東京リージョン無料枠は t3.micro 限定・F1 反映）"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = var.ec2_instance_type == "t3.micro"
    error_message = "ap-northeast-1 では t3.micro のみ無料枠対象（incident-library: 2026-05-09-tokyo-region-t2micro-not-free）。"
  }
}

variable "ec2_key_name" {
  description = "EC2 SSH 用 EC2 Key Pair 名（事前に AWS で作成しておく）"
  type        = string
}

# ----- RDS -----
variable "db_username" {
  description = "RDS マスターユーザー名"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "RDS マスターパスワード（最低 8 文字）"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "RDS パスワードは 8 文字以上必須。"
  }
}
