# =============================================================================
# environments/ ルートTerragrunt設定
# =============================================================================
# このファイルは全環境（dev/staging/prod）で共有されるルート設定。
# 各環境の terragrunt.hcl から include で読み込まれる。
#
# 主な役割:
#   - リモートステートの一元管理（remote_state）
#   - プロバイダ設定の自動生成（generate）
#   - 共通設定の定義
# =============================================================================

# リモートステート設定
# 各環境のステートファイルを環境名で分離して保存する
remote_state {
  backend = "s3"

  config = {
    bucket         = "handson-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "handson-terraform-lock"
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# プロバイダ設定を自動生成
# 全環境で同じプロバイダ設定を使用する
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      ManagedBy = "terragrunt"
      Project   = "handson"
    }
  }
}
EOF
}
