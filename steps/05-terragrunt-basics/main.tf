# =============================================================================
# Step 5: Terragrunt入門 - DRYなインフラ管理
# =============================================================================
# このステップでは以下を学びます:
#   - Terragrunt の基本概念（Terraformのラッパーツール）
#   - terragrunt.hcl の設定方法
#   - inputs による変数の注入
#   - generate によるファイル自動生成
#
# 使い方（Terragruntを使用）:
#   1. terragrunt init    ... 初期化
#   2. terragrunt plan    ... 実行計画
#   3. terragrunt apply   ... 適用
#   4. terragrunt destroy ... 削除
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# S3バケットモジュールの呼び出し
module "s3" {
  source = "../../modules/s3-bucket"

  bucket_name        = var.bucket_name
  environment        = var.environment
  versioning_enabled = var.versioning_enabled
  tags               = var.tags
}
