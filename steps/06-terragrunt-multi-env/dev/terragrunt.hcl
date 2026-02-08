# =============================================================================
# Step 6: dev環境のTerragrunt設定
# =============================================================================
# dev環境はコスト最小限の構成。
# 開発者が自由に試行錯誤できる環境。
# =============================================================================

# 親ディレクトリのterragrunt.hclを継承する
include "root" {
  path = find_in_parent_folders()
}

# Terraformソースコードのパス（親ディレクトリのmain.tfを使用）
terraform {
  source = "../"
}

# dev環境固有の変数値
inputs = {
  project_name = "handson"
  environment  = "dev"

  # ネットワーク設定（小規模）
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

  # EC2設定（最小インスタンス）
  instance_type = "t3.micro"

  tags = {
    Environment = "dev"
    CostCenter  = "development"
  }
}
