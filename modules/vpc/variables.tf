# =============================================================================
# VPCモジュール - 変数定義
# =============================================================================

# VPCの名前プレフィックス
variable "name" {
  description = "VPCおよび関連リソースの名前プレフィックス"
  type        = string
}

# VPCのCIDRブロック
variable "vpc_cidr" {
  description = "VPCのCIDRブロック（例: 10.0.0.0/16）"
  type        = string
  default     = "10.0.0.0/16"
}

# パブリックサブネットのCIDRブロックリスト
variable "public_subnet_cidrs" {
  description = "パブリックサブネットのCIDRブロックのリスト"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# プライベートサブネットのCIDRブロックリスト
variable "private_subnet_cidrs" {
  description = "プライベートサブネットのCIDRブロックのリスト"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

# 使用するアベイラビリティゾーン
variable "availability_zones" {
  description = "サブネットを配置するアベイラビリティゾーンのリスト"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
}

# 環境名
variable "environment" {
  description = "環境名（例: dev, staging, prod）"
  type        = string
  default     = "dev"
}

# 追加タグ
variable "tags" {
  description = "リソースに付与する追加タグ"
  type        = map(string)
  default     = {}
}
