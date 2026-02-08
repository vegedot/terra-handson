# =============================================================================
# environments/dev - 開発環境のTerragrunt設定
# =============================================================================
# 開発環境: コスト最小限、自由に変更可能な環境
#
# 使い方:
#   cd environments/dev
#   terragrunt apply
# =============================================================================

# ルート設定を継承
include "root" {
  path = find_in_parent_folders()
}

# Terraformモジュールのソース指定
# modules/ 配下の共有モジュールを直接参照する
terraform {
  source = "../../modules//s3-bucket"
}

# dev環境固有の変数
inputs = {
  bucket_name        = "handson-dev-app-data"
  environment        = "dev"
  versioning_enabled = true

  tags = {
    Environment = "dev"
    CostCenter  = "development"
  }
}
