# =============================================================================
# EC2インスタンスモジュール - 変数定義
# =============================================================================

# インスタンスの名前
variable "name" {
  description = "EC2インスタンスの名前"
  type        = string
}

# AMI ID（Amazon Machine Image）
variable "ami_id" {
  description = "EC2インスタンスに使用するAMI ID"
  type        = string
}

# インスタンスタイプ（サイズ）
variable "instance_type" {
  description = "EC2インスタンスタイプ（例: t3.micro）"
  type        = string
  default     = "t3.micro"
}

# VPC ID
variable "vpc_id" {
  description = "インスタンスを配置するVPCのID"
  type        = string
}

# サブネットID
variable "subnet_id" {
  description = "インスタンスを配置するサブネットのID"
  type        = string
}

# SSH接続を許可するCIDRブロック
variable "allowed_ssh_cidrs" {
  description = "SSH接続を許可するCIDRブロックのリスト"
  type        = list(string)
  default     = ["0.0.0.0/0"]
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
