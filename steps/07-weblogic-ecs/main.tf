# =============================================================================
# Step 7: WebLogic on ECS Fargate + Oracle RDS SE2
# =============================================================================
# このステップでは以下を学びます:
#   - ECS Fargate でコンテナアプリを動かす仕組み
#   - ECR（Elastic Container Registry）でコンテナイメージを管理する
#   - RDS Oracle SE2 をプライベートサブネットで構築する
#   - ALB（Application Load Balancer）でECSにHTTPルーティングする
#   - Secrets Manager で機密情報（パスワード等）を安全に管理する
#   - NAT Gateway でプライベートサブネットからのアウトバウンド通信を実現する
#
# 使用コミュニティモジュール（https://github.com/terraform-aws-modules）:
#   - terraform-aws-modules/vpc/aws          → vpc.tf
#   - terraform-aws-modules/security-group/aws → security_groups.tf
#   - terraform-aws-modules/alb/aws          → alb.tf
#   - terraform-aws-modules/rds/aws          → rds.tf
#   - terraform-aws-modules/ecs/aws          → ecs.tf
#
# アーキテクチャ:
#   Internet → ALB（パブリックサブネット）→ ECS/WebLogic（プライベート App サブネット）
#                                               ↓
#                                       RDS Oracle（プライベート DB サブネット）
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region

  # --- LocalStack用設定（必要に応じてコメントを外す） ---
  # skip_credentials_validation = true
  # skip_metadata_api_check     = true
  # skip_requesting_account_id  = true
}

locals {
  # リソース名のプレフィックス（例: terra-handson-dev）
  name_prefix = "${var.project_name}-${var.environment}"

  # 全リソースに共通で付与するタグ
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Step        = "07-weblogic-ecs"
    },
    var.tags,
  )
}
