# =============================================================================
# environments/staging - ステージング環境のTerragrunt設定
# =============================================================================
# ステージング環境: 本番に近い構成、リリース前の最終検証用
#
# 使い方:
#   cd environments/staging
#   terragrunt apply
# =============================================================================

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules//s3-bucket"
}

# staging環境固有の変数
inputs = {
  bucket_name        = "handson-staging-app-data"
  environment        = "staging"
  versioning_enabled = true

  tags = {
    Environment = "staging"
    CostCenter  = "staging"
  }
}
