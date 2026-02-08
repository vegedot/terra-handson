# =============================================================================
# environments/prod - 本番環境のTerragrunt設定
# =============================================================================
# 本番環境: 高可用性・高セキュリティ、変更は慎重に行う
#
# 使い方:
#   cd environments/prod
#   terragrunt apply
# =============================================================================

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules//s3-bucket"
}

# prod環境固有の変数
inputs = {
  bucket_name        = "handson-prod-app-data"
  environment        = "prod"
  versioning_enabled = true

  tags = {
    Environment = "prod"
    CostCenter  = "production"
    Critical    = "true"
  }
}
