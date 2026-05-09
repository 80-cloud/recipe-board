# ============================================
# recipe-board / infra / main.tf — Phase 4 B-5-β / γ / δ
# ============================================
# resource / data / provider 宣言。
# - 変数定義: variables.tf
# - 出力定義: outputs.tf
# - 値の雛形: terraform.tfvars.example（実値は terraform.tfvars に書き .gitignore で除外）
#
# 安全方針（CLAUDE.md セクション 12 準拠）:
#   - 新規 VPC を作らず default VPC を流用（NAT Gateway 課金回避）
#   - SSH は自宅 IPv4 / IPv6 限定（0.0.0.0/0 禁止）
#   - RDS SG は EC2 SG からのみ許可（Public アクセス禁止）
#   - RDS は deletion_protection + lifecycle.prevent_destroy の二重ロック
#   - EC2 は IMDSv2 強制 / EBS 暗号化
#   - EIP は EC2 にアタッチ（未アタッチ EIP は課金されるため）
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

# ----- Provider -----
# 変数定義は variables.tf に分離（B-5-δ）。
# 出力は outputs.tf に分離（B-5-δ）。
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

# ============================================
# B-5-γ: EC2 / RDS / EIP 本体
# ============================================

# ----- AMI: Amazon Linux 2023 最新 -----
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ----- EC2 インスタンス -----
# 無料枠: t3.micro × 750h/月（account 単位 / F4）
# IMDSv2 強制 / EBS gp3 8GB / user_data は B-5-ε で追加予定
resource "aws_instance" "app" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.ec2_instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true
  key_name                    = var.ec2_key_name

  metadata_options {
    http_tokens                 = "required" # IMDSv2 強制
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8 # GB（無料枠 30GB 以下）
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project_name}-app"
  }

  lifecycle {
    ignore_changes = [
      ami, # AMI 更新で意図せず置換されるのを防ぐ
    ]
  }
}

# ----- RDS サブネットグループ -----
# RDS は最低 2 つの AZ にまたがるサブネットグループが必須
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# ----- RDS インスタンス -----
# 無料枠: db.t3.micro × 750h/月 / 20GB gp3 / Single-AZ
# 削除困難設定（多層防御）:
#   - deletion_protection = true（AWS 側）
#   - lifecycle.prevent_destroy = true（Terraform 側）
#   → 削除には main.tf の編集 + apply が 2 段階必要
resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-db"
  engine         = "mysql"
  engine_version = "8.4"
  instance_class = "db.t3.micro"

  allocated_storage     = 20 # GB（無料枠上限）
  max_allocated_storage = 20 # autoscaling で 20GB を超えないようにする
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "recipe_board"
  username = var.db_username
  password = var.db_password
  port     = 3306

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  publicly_accessible    = false # F5: 公開禁止
  multi_az               = false # 無料枠維持（倍額回避）

  backup_retention_period = 0    # 学習用（無料枠 storage を消費しない）
  skip_final_snapshot     = true # 学習用（snapshot 課金回避）
  deletion_protection     = true # AWS 側削除保護
  apply_immediately       = true # 学習用（メンテ window を待たない）

  tags = {
    Name = "${var.project_name}-db"
  }

  lifecycle {
    prevent_destroy = true # Terraform 側削除保護（CLAUDE.md 12-3）
  }
}

# ----- Elastic IP -----
# F2 反映: instance 属性で必ず EC2 にアタッチ。
# AWS 課金ルール: running EC2 にアタッチされている EIP のみ無料。
# 停止中 EC2 や未関連付けの EIP は $0.005/時間で課金されるため、
# このリソースは aws_instance.app と一蓮托生で運用する。
resource "aws_eip" "app" {
  instance = aws_instance.app.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-app-eip"
  }

  depends_on = [aws_instance.app]
}
