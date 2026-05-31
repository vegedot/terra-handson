# =============================================================================
# Step 5: 変数定義（Terraformでは手動管理）
# =============================================================================
# ※ 05-terragrunt-basics/variables.tf と同一内容
#
# Terragruntとの対比:
#
#   Terragrunt側（terragrunt.hcl）:
#     inputs = {
#       bucket_name        = "handson-terragrunt-demo"
#       environment        = "dev"
#       versioning_enabled = false
#       tags = { ManagedBy = "terragrunt" }
#     }
#     → terraform.tfvars の代わりに terragrunt.hcl で変数値を管理する
#
#   Terraform側（このファイル + terraform.tfvars）:
#     → variables.tf で型と説明を定義し
#     → terraform.tfvars（または terraform.tfvars.json）で値を管理する
#     → 環境ごとに dev.tfvars / prod.tfvars を用意するのが一般的
# =============================================================================

variable "bucket_name" {
  description = "S3バケット名"
  type        = string
}

variable "environment" {
  description = "環境名"
  type        = string
  default     = "dev"
}

variable "versioning_enabled" {
  description = "バージョニングを有効にするか"
  type        = bool
  default     = true
}

variable "tags" {
  description = "追加タグ"
  type        = map(string)
  default     = {}
}
