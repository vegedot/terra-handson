# =============================================================================
# プロバイダ設定（Terragruntの共通 generate に相当）
# =============================================================================
# Terragruntとの対比:
#
#   Terragrunt側（ルート terragrunt.hcl）:
#     generate "provider" {
#       path      = "provider.tf"
#       if_exists = "overwrite_terragrunt"
#       contents  = <<EOF
#         provider "aws" { region = "ap-northeast-1" }
#       EOF
#     }
#     → 各環境（dev/staging/prod）が include で継承するため、
#       プロバイダ設定は1箇所だけで管理できる
#
#   Terraform側（このファイル）:
#     → フラット構成のため provider.tf は1ファイルで済む
#     → ただしディレクトリ分割構成（環境ごとにディレクトリを作る場合）は
#       各ディレクトリに provider.tf をコピーするか、シンボリックリンクが必要
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
