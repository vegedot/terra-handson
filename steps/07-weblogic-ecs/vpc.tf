# =============================================================================
# ネットワーク構成
# terraform-aws-modules/vpc/aws を使用
# =============================================================================
# このモジュールは以下をまとめて作成します:
#   - VPC本体
#   - パブリックサブネット + インターネットゲートウェイ + パブリックルートテーブル
#   - プライベートサブネット (App用) + プライベートルートテーブル
#   - DBサブネット (RDS用) + DBルートテーブル
#   - NAT Gateway + Elastic IP
#
# 以前は vpc.tf に 100行以上あった設定が、このモジュール1つに集約されます
# =============================================================================

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name_prefix
  cidr = var.vpc_cidr

  azs = var.availability_zones

  # サブネット構成 (3層)
  public_subnets   = var.public_subnet_cidrs      # ALB用
  private_subnets  = var.private_app_subnet_cidrs # ECS用
  database_subnets = var.private_db_subnet_cidrs  # RDS用

  # NAT Gateway設定
  enable_nat_gateway = true
  single_nat_gateway = true # 学習用: 1つを全プライベートサブネットで共有（本番は false 推奨）

  enable_dns_hostnames = true
  enable_dns_support   = true

  # DBサブネットグループはRDSモジュール側で作成するため不要
  create_database_subnet_group = false

  # サブネットへのタグ付け（EKS等で使う場合に必要になるため例として記載）
  public_subnet_tags = {
    Tier = "public"
  }
  private_subnet_tags = {
    Tier = "private-app"
  }
  database_subnet_tags = {
    Tier = "private-db"
  }

  tags = local.common_tags
}
