# =============================================================================
# Step 6: staging環境のTerragrunt設定
# =============================================================================
# staging環境は本番に近い構成。
# リリース前の最終確認を行う環境。
# =============================================================================

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../"
}

# staging環境固有の変数値
inputs = {
  project_name = "handson"
  environment  = "staging"

  # ネットワーク設定（本番に近い構成）
  vpc_cidr             = "10.1.0.0/16"
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.10.0/24", "10.1.20.0/24"]

  # EC2設定（中規模インスタンス）
  instance_type = "t3.small"

  tags = {
    Environment = "staging"
    CostCenter  = "staging"
  }
}
