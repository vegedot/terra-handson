# =============================================================================
# Step 6: Terraform版マルチ環境管理 - Terragruntとの対比
# =============================================================================
# 【構成】
#   単一の .tf コードセットを共有し、環境差分を *.tfvars でルート直下に管理する。
#
#   06-terraform-multi-env/
#   ├── main.tf          ← 全環境共通の Terraform コード
#   ├── variables.tf
#   ├── outputs.tf
#   ├── provider.tf
#   ├── dev.tfvars       ← dev環境の変数値
#   ├── staging.tfvars   ← staging環境の変数値
#   └── prod.tfvars      ← prod環境の変数値
#
# 【重要】-var-file の明示指定が必須
#   *.tfvars はルート直下にあっても自動読み込みされない。
#   必ず -var-file で環境を明示すること。
#
#   terraform plan  -var-file="dev.tfvars"
#   terraform apply -var-file="dev.tfvars"
#   terraform apply -var-file="staging.tfvars"
#   terraform apply -var-file="prod.tfvars"
#
#   -var-file を省略すると対話的に変数入力を求められる（エラーになる）。
#
# 【Terragruntとの対比】
#   Terragrunt: cd dev && terragrunt apply   （環境はディレクトリで表現）
#   Terraform:  terraform apply -var-file="dev.tfvars"  （環境はファイルで表現）
#
# 【run-all 相当機能について】
#   Terraform には run-all 相当の標準機能はない。
#   複数環境への一括適用はスクリプトか CI/CD のマトリックスジョブで代替する。
#   → 依存順序の自動解決・並列制御は Terragrunt に対して劣る。
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
# ※ 06-terragrunt-multi-env/main.tf と同一内容
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
# ※ 06-terragrunt-multi-env/main.tf と同一内容
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
