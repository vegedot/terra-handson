# =============================================================================
# S3バケットモジュール - 変数定義
# =============================================================================

# バケット名（グローバルに一意である必要がある）
variable "bucket_name" {
  description = "S3バケットの名前"
  type        = string
}

# 環境名（dev, staging, prod など）
variable "environment" {
  description = "環境名（例: dev, staging, prod）"
  type        = string
  default     = "dev"
}

# バージョニングを有効にするかどうか
variable "versioning_enabled" {
  description = "S3バケットのバージョニングを有効にするか"
  type        = bool
  default     = true
}

# 追加タグ
variable "tags" {
  description = "リソースに付与する追加タグ"
  type        = map(string)
  default     = {}
}
