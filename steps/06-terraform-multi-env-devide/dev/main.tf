# =============================================================================
# dev環境 - Terraform設定
# =============================================================================
# 【構成の特徴（-devide 構成）】
#   環境ごとにディレクトリを分け、各ディレクトリが独立した Terraform ルートモジュール。
#   各ディレクトリで terraform init / apply を実行するため、
#   ステートファイルは自動的に環境ごとに分離される。
#
# 【課題】
#   1. コードの重複: main.tf / provider.tf が全環境でほぼ同一（DRY 原則に反する）
#   2. run-all がない: スクリプトで代替が必要
#   3. 変更の伝播: モジュール呼び出しを変更した場合、全環境のディレクトリを修正する必要がある
#
# 【実行方法】
#   cd dev
#   terraform init
#   terraform apply
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

module "vpc" {
  source = "../../../modules/vpc"

  name                 = "${var.project_name}-${var.environment}"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  environment          = var.environment
  tags                 = var.tags
}

module "ec2" {
  source = "../../../modules/ec2-instance"

  name          = "${var.project_name}-${var.environment}-web"
  ami_id        = var.ami_id
  instance_type = var.instance_type
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.public_subnet_ids[0]
  environment   = var.environment
  tags          = var.tags
}
