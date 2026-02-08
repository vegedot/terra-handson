# =============================================================================
# Step 2: 変数と出力 - 設定を柔軟にする
# =============================================================================
# このステップでは以下を学びます:
#   - variable（変数）による設定値の外部化
#   - locals（ローカル変数）による値の加工
#   - output（出力）による作成結果の表示
#   - terraform.tfvars による変数値の管理
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

provider "aws" {
  region = "ap-northeast-1"

  # --- LocalStack用設定（必要に応じてコメントを外す） ---
  # skip_credentials_validation = true
  # skip_metadata_api_check     = true
  # skip_requesting_account_id  = true
  # endpoints {
  #   s3  = "http://localhost:4566"
  #   sts = "http://localhost:4566"
  # }
}

# ローカル変数 - 変数を組み合わせて新しい値を作る
locals {
  # 環境名をバケット名に含めて一意にする
  bucket_full_name = "${var.project_name}-${var.environment}-${var.bucket_name}"

  # 共通タグ: すべてのリソースに付与するタグ
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

# S3バケット - 変数を使って柔軟に設定
resource "aws_s3_bucket" "this" {
  bucket = local.bucket_full_name
  tags   = local.common_tags
}

# バージョニング設定
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}
