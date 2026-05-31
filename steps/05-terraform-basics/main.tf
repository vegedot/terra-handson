# =============================================================================
# Step 5: Terraform版 - Terragruntとの対比
# =============================================================================
# Terragruntとの対比:
#
#   Terragrunt                          Terraform
#   ─────────────────────────────────── ──────────────────────────────────────
#   terragrunt.hcl の generate          → provider.tf を手動で管理
#   terragrunt.hcl の inputs            → terraform.tfvars を手動で管理
#   terragrunt.hcl の remote_state      → backend.tf を手動で管理
#
# 使い方（Terraformを使用）:
#   1. terraform init    ... 初期化
#   2. terraform plan    ... 実行計画
#   3. terraform apply   ... 適用
#   4. terraform destroy ... 削除
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

# S3バケットモジュールの呼び出し
# ※ 05-terragrunt-basics/main.tf と同一内容
module "s3" {
  source = "../../modules/s3-bucket"

  bucket_name        = var.bucket_name
  environment        = var.environment
  versioning_enabled = var.versioning_enabled
  tags               = var.tags
}
