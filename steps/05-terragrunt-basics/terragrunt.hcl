# =============================================================================
# Step 5: Terragrunt基本設定
# =============================================================================
# Terragruntは terragrunt.hcl ファイルでTerraformの設定を管理する。
# 主な機能:
#   - generate: プロバイダ設定などを自動生成
#   - inputs:   Terraform変数に値を注入
#   - remote_state: バックエンド設定を一元管理
# =============================================================================

# プロバイダ設定を自動生成する
# この設定により provider.tf が自動的に作成される
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "ap-northeast-1"

  # --- LocalStack用設定（必要に応じてコメントを外す） ---
  # skip_credentials_validation = true
  # skip_metadata_api_check     = true
  # skip_requesting_account_id  = true
  # s3_use_path_style           = true
  # endpoints {
  #   s3  = "http://localhost:4566"
  #   sts = "http://localhost:4566"
  # }
}
EOF
}

# Terraform変数に値を注入する
# terraform.tfvars の代わりにここで管理できる
inputs = {
  bucket_name        = "handson-terragrunt-demo"
  environment        = "dev"
  versioning_enabled = true

  tags = {
    ManagedBy = "terragrunt"
    Step      = "05-terragrunt-basics"
  }
}
