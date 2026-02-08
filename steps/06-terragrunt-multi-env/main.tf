# =============================================================================
# Step 6: マルチ環境管理 - dev/staging/prodの構成
# =============================================================================
# このステップでは以下を学びます:
#   - 環境ごとの terragrunt.hcl 設定
#   - include による親設定の継承
#   - 環境差分の管理（インスタンスサイズ、CIDR等）
#
# ディレクトリ構成:
#   steps/06-terragrunt-multi-env/
#   ├── terragrunt.hcl          # ルート設定（共通設定）
#   ├── main.tf                 # Terraformコード
#   ├── variables.tf            # 変数定義
#   ├── outputs.tf              # 出力定義
#   ├── dev/terragrunt.hcl      # dev環境の設定
#   ├── staging/terragrunt.hcl  # staging環境の設定
#   └── prod/terragrunt.hcl     # prod環境の設定
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

# VPCモジュール
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

# EC2インスタンスモジュール
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
