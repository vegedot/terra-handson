# =============================================================================
# ECS (Elastic Container Service) - Fargate
# =============================================================================
# クラスターの作成に terraform-aws-modules/ecs/aws を使用します。
# タスク定義とサービスは直接リソースとして定義し、設定内容を明示的にします。
# =============================================================================

# CloudWatch Logsグループ（WebLogicのログ出力先）
resource "aws_cloudwatch_log_group" "weblogic" {
  name              = "/ecs/${local.name_prefix}/weblogic"
  retention_in_days = 30

  tags = local.common_tags
}

# =============================================================================
# ECS クラスター
# terraform-aws-modules/ecs/aws でクラスターと Fargate 設定を管理
# =============================================================================

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.0"

  cluster_name = "${local.name_prefix}-cluster"

  # Fargate キャパシティプロバイダー
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
        base   = 1
      }
    }
  }

  # Container Insights を有効化（クラスターレベルのメトリクス収集）
  cluster_settings = {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.common_tags
}

# =============================================================================
# ECS タスク定義（WebLogic）
# コンテナの仕様を定義する「設計図」
# =============================================================================

resource "aws_ecs_task_definition" "weblogic" {
  family                   = "${local.name_prefix}-weblogic"
  cpu                      = var.weblogic_cpu    # 2048 = 2 vCPU
  memory                   = var.weblogic_memory # 4096 = 4 GB
  network_mode             = "awsvpc"            # Fargate には awsvpc が必須
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "weblogic"
      image     = var.weblogic_image_uri
      essential = true

      portMappings = [
        {
          containerPort = var.weblogic_admin_port
          hostPort      = var.weblogic_admin_port
          protocol      = "tcp"
        }
      ]

      # 非機密の環境変数
      environment = [
        { name = "DOMAIN_NAME", value = "base_domain" },
        { name = "ADMIN_LISTEN_PORT", value = tostring(var.weblogic_admin_port) },
        # RDS 接続情報（ホスト・ポート・DB名は非機密として環境変数に設定）
        { name = "DB_HOST", value = module.rds.db_instance_address },
        { name = "DB_PORT", value = "1521" },
        { name = "DB_NAME", value = var.db_name },
        { name = "DB_USERNAME", value = var.db_username },
      ]

      # 機密情報は Secrets Manager から動的取得
      # "<ARN>:<JSON-KEY>::" 形式で JSON シークレットの特定キーを参照できる
      secrets = [
        {
          name      = "ADMIN_USERNAME"
          valueFrom = "${aws_secretsmanager_secret.weblogic_admin.arn}:username::"
        },
        {
          name      = "ADMIN_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.weblogic_admin.arn}:password::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.rds_password.arn}:password::"
        },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.weblogic.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "weblogic"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -s -o /dev/null -w '%%{http_code}' http://localhost:${tostring(var.weblogic_admin_port)}/console | grep -qE '^(200|302|401)$' || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 5
        startPeriod = 180 # WebLogicの起動には3分程度かかる場合がある
      }
    }
  ])

  tags = local.common_tags
}

# =============================================================================
# ECS サービス（WebLogic）
# タスクの常時稼働とALBとの紐付けを管理
# =============================================================================

resource "aws_ecs_service" "weblogic" {
  name            = "${local.name_prefix}-weblogic"
  cluster         = module.ecs_cluster.cluster_arn
  task_definition = aws_ecs_task_definition.weblogic.arn
  desired_count   = var.weblogic_desired_count
  launch_type     = "FARGATE"

  force_new_deployment = true

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [module.ecs_sg.security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = module.alb.target_groups["weblogic"].arn
    container_name   = "weblogic"
    container_port   = var.weblogic_admin_port
  }

  depends_on = [
    module.alb,
    aws_iam_role_policy_attachment.ecs_task_execution,
    aws_iam_role_policy.ecs_secrets_access,
    module.rds,
    aws_secretsmanager_secret_version.rds_password,
    aws_secretsmanager_secret_version.weblogic_admin,
  ]

  tags = local.common_tags
}
