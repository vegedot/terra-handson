# =============================================================================
# Step 5: Terragrunt基本設定
# =============================================================================
# Terragruntは terragrunt.hcl ファイルでTerraformの設定を管理する。
# 主な機能:
#   - generate:     プロバイダ設定などバックエンド以外のファイルを自動生成
#   - inputs:       Terraform変数に値を注入
#   - remote_state: バックエンド設定を一元管理（Part 2で使用）
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
  # access_key = "mock_access_key"
  # secret_key  = "mock_secret_key"
  
  # endpoints {
  #   s3  = "http://localhost:4566"
  #   sts = "http://localhost:4566"
  #}
}
EOF
}

# =============================================================================
# Part 2: remote_state によるバックエンド設定（LocalStack用）
# =============================================================================
# 以下のコメントを外すと、S3バックエンドを remote_state で管理できる。
# generate のみでバックエンドを設定するアプローチとの違いは:
#   - Terragrunt 自身が state の場所を「理解する」
#   - dependency ブロックが使用可能になる
#   - run_all の依存順序制御が機能する
#   - S3バケットが存在しなければ自動作成される
# =============================================================================
# remote_state {
#   backend = "s3"
#   config = {
#     bucket   = "terragrunt-state-bucket"
#     key      = "${path_relative_to_include()}/terraform.tfstate"
#     region   = "ap-northeast-1"
#     encrypt  = false
#
#     # LocalStack用設定
#     endpoint                    = "http://localhost:4566"
#     sts_endpoint                = "http://localhost:4566"
#     force_path_style            = true
#     skip_credentials_validation = true
#     skip_metadata_api_check     = true
#     skip_requesting_account_id  = true
#     access_key                  = "mock_access_key"
#     secret_key                  = "mock_secret_key"
#   }
#   generate = {
#     path      = "backend.tf"
#     if_exists = "overwrite_terragrunt"
#   }
# }

# Terraform変数に値を注入する
# terraform.tfvars の代わりにここで管理できる
inputs = {
  bucket_name        = "handson-terragrunt-demo"
  environment        = "dev"
  #versioning_enabled = true
  versioning_enabled = false

  tags = {
    ManagedBy = "terragrunt"
    Step      = "05-terragrunt-basics"
    Updated   = "true"
  }
}
