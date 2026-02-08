# =============================================================================
# Step 6: 変数定義
# =============================================================================

variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "handson"
}

variable "environment" {
  description = "環境名"
  type        = string
}

variable "vpc_cidr" {
  description = "VPCのCIDRブロック"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "パブリックサブネットのCIDRブロック"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "プライベートサブネットのCIDRブロック"
  type        = list(string)
}

variable "availability_zones" {
  description = "アベイラビリティゾーン"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
}

variable "ami_id" {
  description = "EC2インスタンスのAMI ID"
  type        = string
  default     = "ami-0d52744d6551d851e"
}

variable "instance_type" {
  description = "EC2インスタンスタイプ"
  type        = string
}

variable "tags" {
  description = "追加タグ"
  type        = map(string)
  default     = {}
}
