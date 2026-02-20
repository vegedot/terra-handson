# =============================================================================
# Step 7: 変数定義
# =============================================================================

# -----------------------------------------------------------------------------
# 基本設定
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "プロジェクト名（リソース名のプレフィックスとして使用）"
  type        = string
  default     = "terra-handson"
}

variable "environment" {
  description = "環境名"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "環境名は dev, staging, prod のいずれかを指定してください。"
  }
}

variable "region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "tags" {
  description = "全リソースに付与する追加タグ"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# ネットワーク設定
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "VPCのCIDRブロック"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "使用するアベイラビリティゾーン（2つ以上必要）"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
}

variable "public_subnet_cidrs" {
  description = "パブリックサブネットのCIDRブロック（ALB用）"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "プライベートアプリサブネットのCIDRブロック（ECS用）"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "プライベートDBサブネットのCIDRブロック（RDS用）"
  type        = list(string)
  default     = ["10.0.30.0/24", "10.0.40.0/24"]
}

# -----------------------------------------------------------------------------
# 踏み台EC2設定
# -----------------------------------------------------------------------------

variable "bastion_instance_type" {
  description = "踏み台EC2インスタンスタイプ（Windows Server 2022）"
  type        = string
  default     = "t3.medium"
}

# -----------------------------------------------------------------------------
# WebLogic / ECS設定
# -----------------------------------------------------------------------------

variable "weblogic_image_uri" {
  description = <<-EOT
    WebLogicコンテナイメージのURI（ECRリポジトリURIを指定）
    例: 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/terra-handson-dev-weblogic:14.1.1
    ※ apply前にDockerイメージをECRにpushしておく必要があります
    ※ イメージのビルド・push手順はREADME.mdを参照してください
  EOT
  type        = string
}

variable "weblogic_admin_username" {
  description = "WebLogic管理コンソールのユーザー名"
  type        = string
  default     = "weblogic"
}

variable "weblogic_admin_password" {
  description = "WebLogic管理コンソールのパスワード（8文字以上）"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.weblogic_admin_password) >= 8
    error_message = "WebLogicパスワードは8文字以上で指定してください。"
  }
}

variable "weblogic_cpu" {
  description = <<-EOT
    ECSタスクのCPUユニット
    Fargate有効な値: 256, 512, 1024, 2048, 4096
    WebLogicは最低2048 (2 vCPU) を推奨
  EOT
  type        = number
  default     = 2048
}

variable "weblogic_memory" {
  description = <<-EOT
    ECSタスクのメモリ（MB）
    WebLogicは最低4096 (4 GB) を推奨
    CPUに対して有効な値はAWSドキュメントを参照
  EOT
  type        = number
  default     = 4096
}

variable "weblogic_admin_port" {
  description = "WebLogic管理サーバーのHTTPポート"
  type        = number
  default     = 7001
}

variable "weblogic_desired_count" {
  description = "ECSサービスの希望タスク数（学習用は1で十分）"
  type        = number
  default     = 1
}

# -----------------------------------------------------------------------------
# RDS Oracle設定
# -----------------------------------------------------------------------------

variable "db_username" {
  description = "RDS Oracleのマスターユーザー名"
  type        = string
  default     = "weblogic"
}

variable "db_name" {
  description = "OracleのDB名（SID）。8文字以内で英大文字から始まる必要があります"
  type        = string
  default     = "WLSDB"

  validation {
    condition     = can(regex("^[A-Z][A-Z0-9]{0,7}$", var.db_name))
    error_message = "DB名は大文字英字で始まる1〜8文字の英数字を指定してください。"
  }
}

variable "db_instance_class" {
  description = "RDSインスタンスタイプ（Oracle SE2 LIの最小: db.t3.small）"
  type        = string
  default     = "db.t3.small"
}

variable "db_engine_version" {
  description = <<-EOT
    Oracle SE2のエンジンバージョン
    利用可能バージョン確認: aws rds describe-db-engine-versions --engine oracle-se2
  EOT
  type        = string
  default     = "19.0.0.0.ru-2024-10.rur-2024-10.r1"
}

variable "db_allocated_storage" {
  description = "RDSのストレージ容量（GB）。Oracleの最小値は20GB"
  type        = number
  default     = 50
}

variable "db_multi_az" {
  description = "RDSのマルチAZ配置。本番環境ではtrueを推奨（コスト増加に注意）"
  type        = bool
  default     = false
}
