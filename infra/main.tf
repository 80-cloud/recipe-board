# ============================================
# recipe-board / infra / main.tf — 骨格（Phase 4 B-5-β）
# ============================================
# このファイルは VPC（参照のみ） / SG の宣言までを含む骨格。
# EC2 / RDS / EIP は B-5-γ で追記する。
# variables.tf / outputs.tf / terraform.tfvars.example は B-5-δ で分離する。
#
# 安全方針（CLAUDE.md セクション 12 準拠）:
#   - 新規 VPC を作らず default VPC を流用（NAT Gateway 課金回避）
#   - SSH は自宅 IPv4 / IPv6 限定（0.0.0.0/0 禁止）
#   - RDS SG は EC2 SG からのみ許可（Public アクセス禁止）
#   - terraform.tfvars と tfstate は infra/.gitignore（PR #62）で除外済み
# ============================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ----- 変数（B-5-δ で variables.tf に分離予定）-----
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

variable "home_ipv4_cidr" {
  description = "自宅 IPv4 CIDR（SSH 許可元、例: 203.0.113.10/32）"
  type        = string
  sensitive   = true
}

variable "home_ipv6_cidr" {
  description = "自宅 IPv6 CIDR（SSH 許可元、例: 2001:db8::/64）"
  type        = string
  sensitive   = true
}

# ----- Provider -----
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }
}

# ----- デフォルト VPC / Subnet を参照（新規作成しない）-----
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ----- EC2 用 SG -----
# 受信: SSH（自宅のみ） / HTTP 80（全世界、Nginx でリバースプロキシ）
# 送信: 全許可（Terraform は明示しないと egress 空になる）
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "EC2: SSH from home, HTTP from anywhere"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from home (IPv4)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.home_ipv4_cidr]
  }

  ingress {
    description      = "SSH from home (IPv6)"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    ipv6_cidr_blocks = [var.home_ipv6_cidr]
  }

  ingress {
    description      = "HTTP from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "All outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# ----- RDS 用 SG -----
# 受信: 3306 を EC2 SG からのみ許可（Public アクセス禁止）
# 送信: 全許可（RDS が外部に出ることは無いが、Terraform 既定挙動の安全側で明示）
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "RDS: MySQL 3306 from EC2 SG only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "MySQL from EC2 SG"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}
