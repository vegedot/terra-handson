# =============================================================================
# バックエンド設定（Terragruntの remote_state に相当）
# =============================================================================
# Terragruntとの対比:
#
#   Terragrunt側（terragrunt.hcl の remote_state ブロック）:
#     remote_state {
#       backend = "s3"
#       config = {
#         bucket = "terragrunt-state-bucket"
#         key    = "${path_relative_to_include()}/terraform.tfstate"
#         region = "ap-northeast-1"
#       }
#       generate = {
#         path      = "backend.tf"
#         if_exists = "overwrite_terragrunt"
#       }
#     }
#     メリット:
#       - S3バケットが存在しなければ自動作成
#       - backend.tf を自動生成（このファイルを手動で用意不要）
#       - dependency ブロックでモジュール間の依存解決が可能
#       - run_all で依存順序を制御できる
#
#   Terraform側（このファイル）:
#     → backend.tf を手動で作成・管理する必要がある
#     → S3バケットは事前に手動で作成しておく必要がある
#     → バックエンド設定の変更時は terraform init -reconfigure が必要
# =============================================================================

# --- S3バックエンド（LocalStack用）---
# 使用する場合は以下のコメントを外す。
# 事前に S3バケット "terraform-state-bucket" を作成しておくこと。
#
# terraform {
#   backend "s3" {
#     bucket = "terraform-state-bucket"
#     key    = "05-terraform-basics/terraform.tfstate"
#     region = "ap-northeast-1"
#
#     # LocalStack用設定
#     endpoint                    = "http://localhost:4566"
#     sts_endpoint                = "http://localhost:4566"
#     force_path_style            = true
#     skip_credentials_validation = true
#     skip_metadata_api_check     = true
#     skip_requesting_account_id  = true
#     access_key                  = "mock_access_key"
#     secret_key                  = "mock_secret_key"
#   }
# }
