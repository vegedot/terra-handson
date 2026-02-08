# =============================================================================
# Step 2: 変数定義
# =============================================================================
# 変数の型には以下がある:
#   - string: 文字列
#   - number: 数値
#   - bool:   真偽値
#   - list:   リスト（配列）
#   - map:    マップ（辞書）
#   - object: オブジェクト（構造体）
# =============================================================================

# プロジェクト名
variable "project_name" {
  description = "プロジェクト名（リソース名のプレフィックスに使用）"
  type        = string
  default     = "handson"
}

# バケット名
variable "bucket_name" {
  description = "S3バケットの名前（環境名とプロジェクト名が自動付与される）"
  type        = string
  default     = "data"

  # バリデーション: バケット名の長さを制限
  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 30
    error_message = "バケット名は3文字以上30文字以下で指定してください。"
  }
}

# 環境名
variable "environment" {
  description = "環境名（dev, staging, prod のいずれか）"
  type        = string
  default     = "dev"

  # バリデーション: 許可された環境名のみ受け付ける
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "環境名は dev, staging, prod のいずれかを指定してください。"
  }
}

# 追加タグ
variable "tags" {
  description = "リソースに付与する追加のタグ"
  type        = map(string)
  default     = {}
}
