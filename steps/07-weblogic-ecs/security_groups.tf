# =============================================================================
# セキュリティグループ
# =============================================================================
# 最小権限の原則に従い、必要な通信のみを許可します
#
# 通信フロー:
#   Internet -> ALB (port 80)
#   ALB -> ECS/WebLogic (port 7001) ※ALBからのみ
#   ECS/WebLogic -> RDS Oracle (port 1521) ※ECSからのみ
#   ECS/WebLogic -> Internet (NAT経由、ECR/SecretsManager/CloudWatch向け)
# =============================================================================

# -----------------------------------------------------------------------------
# ALB セキュリティグループ
# インターネットからHTTPアクセスを受け付ける
# -----------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "ALB - Allow HTTP from internet"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    { Name = "${local.name_prefix}-alb-sg" },
    local.common_tags,
  )
}

# -----------------------------------------------------------------------------
# ECS タスク（WebLogic）セキュリティグループ
# ALBからのトラフィックのみ受け入れ、外部への通信はNAT Gateway経由
# -----------------------------------------------------------------------------

resource "aws_security_group" "ecs_tasks" {
  name        = "${local.name_prefix}-ecs-tasks-sg"
  description = "ECS WebLogic tasks - Allow inbound from ALB only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "WebLogic admin port from ALB only"
    from_port       = var.weblogic_admin_port
    to_port         = var.weblogic_admin_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound - ECR pull, Secrets Manager, CloudWatch, RDS"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    { Name = "${local.name_prefix}-ecs-tasks-sg" },
    local.common_tags,
  )
}

# -----------------------------------------------------------------------------
# RDS Oracle セキュリティグループ
# ECSタスクからのOracle接続（1521番ポート）のみ許可
# -----------------------------------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "RDS Oracle - Allow Oracle port from ECS tasks only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Oracle DB from ECS tasks only"
    from_port       = 1521
    to_port         = 1521
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    { Name = "${local.name_prefix}-rds-sg" },
    local.common_tags,
  )
}
