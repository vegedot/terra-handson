# =============================================================================
# プロバイダ設定（Terraformでは手動管理）
# =============================================================================
# Terragruntとの対比:
#
#   Terragrunt側（terragrunt.hcl）:
#     generate "provider" {
#       path      = "provider.tf"
#       if_exists = "overwrite_terragrunt"
#       contents  = <<EOF
#         provider "aws" { ... }
#       EOF
#     }
#     → Terragrunt が provider.tf を自動生成・上書きする
#
#   Terraform側（このファイル）:
#     → provider.tf を手動で作成・管理する必要がある
#     → 複数環境で同じ設定を使う場合はコピーが必要になる（DRY原則に反する）
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
  # }
}
