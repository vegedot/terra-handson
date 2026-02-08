# =============================================================================
# Step 6: ルートTerragrunt設定（共通設定）
# =============================================================================
# このファイルは各環境（dev/staging/prod）から include で読み込まれる。
# 共通のプロバイダ設定やバックエンド設定をここに定義する。
#
# 使い方:
#   cd dev && terragrunt apply     # dev環境をデプロイ
#   cd staging && terragrunt apply # staging環境をデプロイ
#   cd prod && terragrunt apply    # prod環境をデプロイ
#
#   terragrunt run-all apply       # 全環境を一括デプロイ
# =============================================================================

# プロバイダ設定を自動生成
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "ap-northeast-1"
}
EOF
}
