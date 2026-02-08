# =============================================================================
# Step 5: 変数定義
# =============================================================================
# Terragruntでは terragrunt.hcl の inputs ブロックから値を注入する。
# terraform.tfvars を使わなくても変数を設定できる。
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
