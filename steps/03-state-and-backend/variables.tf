# =============================================================================
# Step 3: 変数定義
# =============================================================================

variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "handson"
}

variable "environment" {
  description = "環境名（例: dev, staging, prod）"
  type        = string
  default     = "dev"
}
