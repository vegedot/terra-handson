# =============================================================================
# プロバイダ設定（dev環境）
# =============================================================================
# 【課題】 -devide 構成では全環境に provider.tf をコピーする必要がある。
# Terragrunt では include + generate により1箇所で管理できる。
# =============================================================================

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
  #   ec2 = "http://localhost:4566"
  # }
}
