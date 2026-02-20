# =============================================================================
# セキュリティグループ
# terraform-aws-modules/security-group/aws を使用
# =============================================================================
# 通信フロー（Internal構成）:
#   踏み台EC2 --port 80--> Internal ALB --port 7001--> WebLogic(ECS)
#                                                            |
#                                              port 1521 --> RDS Oracle
#
# ALBのセキュリティグループはALBモジュール側で作成
# =============================================================================

# -----------------------------------------------------------------------------
# 踏み台EC2 用セキュリティグループ
# SSMはアウトバウンドHTTPS接続のみ使用するため、インバウンドは不要
# RDP(3389)はVPN等でVPC内から直接アクセスする場合に使用
# -----------------------------------------------------------------------------

module "bastion_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name_prefix}-bastion-sg"
  description = "Bastion EC2 - SSM management, no inbound required"
  vpc_id      = module.vpc.vpc_id

  # SSM Session Manager はアウトバウンドのみで動作するため、インバウンドルール不要
  # ※ VPN等でVPC内から直接RDPする場合は以下のルールを有効化:
  # ingress_with_cidr_blocks = [
  #   {
  #     from_port   = 3389
  #     to_port     = 3389
  #     protocol    = "tcp"
  #     description = "RDP from VPC (e.g. corporate VPN)"
  #     cidr_blocks = var.vpc_cidr
  #   }
  # ]

  # アウトバウンド: SSMエンドポイント通信 + WebLogic/ALBへのアクセス
  egress_rules = ["all-all"]

  tags = merge(
    { Name = "${local.name_prefix}-bastion-sg" },
    local.common_tags,
  )
}

# -----------------------------------------------------------------------------
# ECS タスク（WebLogic）用セキュリティグループ
# Internal ALBと踏み台EC2からのみ WebLogic ポートへのアクセスを許可
# -----------------------------------------------------------------------------

module "ecs_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name_prefix}-ecs-tasks-sg"
  description = "ECS WebLogic tasks - Allow from ALB and bastion"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = var.weblogic_admin_port
      to_port                  = var.weblogic_admin_port
      protocol                 = "tcp"
      description              = "WebLogic port from Internal ALB"
      source_security_group_id = module.alb.security_group_id
    },
    {
      from_port                = var.weblogic_admin_port
      to_port                  = var.weblogic_admin_port
      protocol                 = "tcp"
      description              = "WebLogic port from bastion (direct debug access)"
      source_security_group_id = module.bastion_sg.security_group_id
    },
  ]

  egress_rules = ["all-all"]

  tags = merge(
    { Name = "${local.name_prefix}-ecs-tasks-sg" },
    local.common_tags,
  )
}

# -----------------------------------------------------------------------------
# RDS Oracle 用セキュリティグループ
# ECSタスクのセキュリティグループからのみ Oracle ポート (1521) を許可
# -----------------------------------------------------------------------------

module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name_prefix}-rds-sg"
  description = "RDS Oracle - Allow Oracle port from ECS tasks only"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 1521
      to_port                  = 1521
      protocol                 = "tcp"
      description              = "Oracle DB from ECS tasks only"
      source_security_group_id = module.ecs_sg.security_group_id
    }
  ]

  egress_rules = ["all-all"]

  tags = merge(
    { Name = "${local.name_prefix}-rds-sg" },
    local.common_tags,
  )
}
