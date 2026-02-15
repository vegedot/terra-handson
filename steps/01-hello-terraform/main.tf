# =============================================================================
# Step 1: Hello Terraform - 最初のTerraformコード
# =============================================================================
# このステップでは、Terraformの基本を学びます:
#   - HCL（HashiCorp Configuration Language）の基本構文
#   - provider（プロバイダ）の設定
#   - resource（リソース）の定義
#   - terraform init / plan / apply / destroy のワークフロー
#
# 使い方:
#   1. terraform init    ... プロバイダのダウンロードと初期化
#   2. terraform plan    ... 実行計画の確認（何が作成されるか）
#   3. terraform apply   ... リソースの作成
#   4. terraform destroy ... リソースの削除
# =============================================================================

terraform {
  # Terraformのバージョン制約
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWSプロバイダの設定
# LocalStackを使用する場合は、下記のプロバイダブロックを削除し、
# providers.tf のコメントを外してください（詳細は providers.tf を参照）
provider "aws" {
  region = "ap-northeast-1"

  # --- LocalStack用の設定（ローカル開発時に有効化） ---
  # LocalStackを使う場合は以下のコメントを外してください
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true
  
  endpoints {
    s3  = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

# S3バケットの作成 - 最もシンプルなリソース定義の例
resource "aws_s3_bucket" "my_first_bucket" {
  # バケット名はグローバルに一意である必要がある
  # 自分の名前やプロジェクト名を含めると衝突を避けやすい
  bucket = "my-first-terraform-bucket-handson"

  tags = {
    Name      = "My First Bucket"
    ManagedBy = "terraform"
  }
}
