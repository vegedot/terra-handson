# =============================================================================
# Step 6: prod環境のTerragrunt設定
# =============================================================================
# prod環境は高可用性・高セキュリティの構成。
# 変更は慎重に行い、必ずstagingで検証してから適用する。
# =============================================================================

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../"
}

# prod環境固有の変数値
inputs = {
  project_name = "handson"
  environment  = "prod"

  # ネットワーク設定（本番用）
  vpc_cidr             = "10.2.0.0/16"
  public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24"]
  private_subnet_cidrs = ["10.2.10.0/24", "10.2.20.0/24"]

  # EC2設定（本番用インスタンス）
  instance_type = "t3.medium"

  tags = {
    Environment = "prod"
    CostCenter  = "production"
    Critical    = "true"
  }
}
