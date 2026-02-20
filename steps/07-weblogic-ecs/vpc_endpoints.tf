# =============================================================================
# VPCエンドポイント
# プライベートサブネット内のリソースがインターネットを経由せずに
# AWSサービスと通信するためのエンドポイント
# =============================================================================
#
# 追加するエンドポイント:
#   Interface型（有料）:
#     ssm         - SSM API（Session Managerの制御）
#     ssmmessages - Session Managerのデータ転送
#     ※ ec2messages は Run Command 用のため不要（Session Manager のみ使用）
#
#   Gateway型（無料）:
#     s3 - ECSがECRのイメージレイヤーをS3経由でpullする際に使用
#          ※ NAT Gateway経由より高速・コスト削減
#
# 注意: Interface型エンドポイントはENI+時間課金あり（1エンドポイント約$7/月）
# =============================================================================

# VPCエンドポイント用セキュリティグループ（Interface型エンドポイント共通）
module "vpc_endpoints_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name_prefix}-vpce-sg"
  description = "VPC Endpoints - Allow HTTPS from VPC"
  vpc_id      = module.vpc.vpc_id

  # VPC内の全リソースからHTTPSアクセスを許可
  ingress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS from VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    }
  ]

  egress_rules = ["all-all"]

  tags = merge(
    { Name = "${local.name_prefix}-vpce-sg" },
    local.common_tags,
  )
}

# =============================================================================
# SSM Session Manager 用 Interface エンドポイント（2点セット）
# Session Manager には ssm + ssmmessages の2つが必要です。
# ※ ec2messages は SSM Run Command 用のため、Session Manager には不要
# =============================================================================

# SSM API エンドポイント
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [module.vpc_endpoints_sg.security_group_id]
  private_dns_enabled = true # VPC内でAWSのDNS名をそのまま使用可能にする

  tags = merge(
    { Name = "${local.name_prefix}-ssm-endpoint" },
    local.common_tags,
  )
}

# Session Manager データ転送エンドポイント
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [module.vpc_endpoints_sg.security_group_id]
  private_dns_enabled = true

  tags = merge(
    { Name = "${local.name_prefix}-ssmmessages-endpoint" },
    local.common_tags,
  )
}

# =============================================================================
# S3 Gateway エンドポイント（無料）
# ECRのイメージレイヤーはS3に保存されているため、このエンドポイントがあると
# NAT Gatewayを経由しないためコスト削減と通信速度の向上になります
# =============================================================================

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids

  tags = merge(
    { Name = "${local.name_prefix}-s3-endpoint" },
    local.common_tags,
  )
}
