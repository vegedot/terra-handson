# =============================================================================
# Step 4: モジュール - コードの再利用
# =============================================================================
# このステップでは以下を学びます:
#   - モジュールの呼び出し方（module ブロック）
#   - モジュールへの変数の渡し方
#   - モジュールの出力の参照方法
#   - modules/ ディレクトリの共有モジュール活用
#
# ここでは modules/ 配下のVPC、EC2、S3モジュールを呼び出して
# 一つのインフラ環境を構築します。
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"

  # --- LocalStack用設定（必要に応じてコメントを外す） ---
  # skip_credentials_validation = true
  # skip_metadata_api_check     = true
  # skip_requesting_account_id  = true
  # s3_use_path_style           = true
  # endpoints {
  #   s3       = "http://localhost:4566"
  #   sts      = "http://localhost:4566"
  #   ec2      = "http://localhost:4566"
  #   dynamodb = "http://localhost:4566"
  # }
}

# VPCモジュールの呼び出し
# ネットワーク基盤（VPC、サブネット、IGW）を作成する
module "vpc" {
  source = "../../modules/vpc"

  name                 = "${var.project_name}-${var.environment}"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  environment          = var.environment
  tags                 = var.tags
}

# EC2インスタンスモジュールの呼び出し
# VPCモジュールの出力を参照してサブネットにインスタンスを配置する
module "ec2" {
  source = "../../modules/ec2-instance"

  name          = "${var.project_name}-${var.environment}-web"
  ami_id        = var.ami_id
  instance_type = var.instance_type
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.public_subnet_ids[0]
  environment   = var.environment
  tags          = var.tags
}

# S3バケットモジュールの呼び出し
# アプリケーションデータ保存用のバケットを作成する
module "s3" {
  source = "../../modules/s3-bucket"

  bucket_name        = "${var.project_name}-${var.environment}-app-data"
  environment        = var.environment
  versioning_enabled = true
  tags               = var.tags
}
