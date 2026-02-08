# =============================================================================
# Step 1: プロバイダ設定（LocalStack対応版）
# =============================================================================
# このファイルは、LocalStackを使ったローカル開発用のプロバイダ設定例です。
# main.tf のプロバイダ設定と併用する場合は、main.tf 側のproviderブロックを
# 削除してから、このファイルのコメントを外してください。
#
# LocalStackとは:
#   AWSサービスをローカルでエミュレートするツールです。
#   AWSアカウントがなくてもTerraformの学習ができます。
#
# LocalStackの起動方法:
#   docker run --rm -p 4566:4566 localstack/localstack
# =============================================================================

# --- LocalStack用プロバイダ設定（使用時はコメントを外す） ---
# provider "aws" {
#   region                      = "ap-northeast-1"
#   access_key                  = "test"
#   secret_key                  = "test"
#   skip_credentials_validation = true
#   skip_metadata_api_check     = true
#   skip_requesting_account_id  = true
#
#   endpoints {
#     s3       = "http://localhost:4566"
#     sts      = "http://localhost:4566"
#     dynamodb = "http://localhost:4566"
#     ec2      = "http://localhost:4566"
#     iam      = "http://localhost:4566"
#   }
# }
