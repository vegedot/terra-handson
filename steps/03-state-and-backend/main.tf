# =============================================================================
# Step 3: ステートとバックエンド
# =============================================================================
# このステップでは以下を学びます:
#   - terraform.tfstate の役割（リソースの状態を記録するファイル）
#   - ローカルステート vs リモートステート
#   - S3バックエンド（チームでのステート共有）
#   - DynamoDBによるステートロック（同時変更の防止）
#
# ここでは、リモートバックエンド用のインフラ自体を作成します。
# 作成後に backend.tf の設定を有効化してステートを移行できます。
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
  #   s3       = "http://localhost:4566"
  #   sts      = "http://localhost:4566"
  #   dynamodb = "http://localhost:4566"
  # }
}

locals {
  state_bucket_name = "${var.project_name}-${var.environment}-terraform-state"
  lock_table_name   = "${var.project_name}-${var.environment}-terraform-lock"
}

# ステートファイルを保存するS3バケット
resource "aws_s3_bucket" "terraform_state" {
  bucket = local.state_bucket_name

  # 誤って削除しないように保護（学習時は false にしておく）
  force_destroy = true

  tags = {
    Name        = local.state_bucket_name
    Purpose     = "Terraform State"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ステートバケットのバージョニング有効化
# ステートファイルの変更履歴を保持し、問題が発生した場合に復元可能にする
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ステートバケットの暗号化設定
# ステートファイルには機密情報が含まれる可能性があるため暗号化する
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ステートロック用のDynamoDBテーブル
# terraform apply の同時実行を防ぎ、ステートの破損を防止する
resource "aws_dynamodb_table" "terraform_lock" {
  name         = local.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = local.lock_table_name
    Purpose     = "Terraform State Lock"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
