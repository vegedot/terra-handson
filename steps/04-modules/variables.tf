# =============================================================================
# Step 4: 変数定義
# =============================================================================

variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "handson"
}

variable "environment" {
  description = "環境名"
  type        = string
  default     = "dev"
}

# VPC関連の変数
variable "vpc_cidr" {
  description = "VPCのCIDRブロック"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "パブリックサブネットのCIDRブロック"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "プライベートサブネットのCIDRブロック"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "availability_zones" {
  description = "アベイラビリティゾーン"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
}

# EC2関連の変数
variable "ami_id" {
  description = "EC2インスタンスのAMI ID（Amazon Linux 2023）"
  type        = string
  default     = "ami-0d52744d6551d851e"
}

variable "instance_type" {
  description = "EC2インスタンスタイプ"
  type        = string
  default     = "t3.micro"
}

# 共通タグ
variable "tags" {
  description = "すべてのリソースに付与する追加タグ"
  type        = map(string)
  default     = {}
}
