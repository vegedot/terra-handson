# =============================================================================
# ECS (Elastic Container Service) - Fargate
# WebLogicコンテナの実行環境
# =============================================================================
# 構成要素:
#   - CloudWatch Logs グループ: コンテナログの収集先
#   - ECS クラスター: タスクの実行環境
#   - ECS タスク定義: コンテナ仕様（イメージ・CPU/Memory・環境変数・ポート）
#   - ECS サービス: タスクの常時稼働を保証し、ALBと連携
# =============================================================================

# CloudWatch Logsグループ（WebLogicのログ出力先）
resource "aws_cloudwatch_log_group" "weblogic" {
  name              = "/ecs/${local.name_prefix}/weblogic"
  retention_in_days = 30 # 30日間ログを保持

  tags = local.common_tags
}

# ECSクラスター
resource "aws_ecs_cluster" "this" {
  name = "${local.name_prefix}-cluster"

  # Container Insights を有効化（パフォーマンスメトリクスの可視化）
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.common_tags
}

# =============================================================================
# ECSタスク定義（WebLogic）
# コンテナの仕様を定義する「設計図」です。実際の実行はECSサービスが行います。
# =============================================================================

resource "aws_ecs_task_definition" "weblogic" {
  family                   = "${local.name_prefix}-weblogic"
  cpu                      = var.weblogic_cpu    # 2048 = 2 vCPU
  memory                   = var.weblogic_memory # 4096 = 4 GB
  network_mode             = "awsvpc"            # Fargateには awsvpc が必須
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = aws_iam_role.ecs_task_execution.arn # エージェント用ロール
  task_role_arn      = aws_iam_role.ecs_task.arn           # アプリ用ロール

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

      # 非機密の環境変数（コンテナ起動時に注入）
      # WebLogicイメージのDockerfileでこれらの変数を参照するよう実装してください
      environment = [
        {
          name  = "DOMAIN_NAME"
          value = "base_domain"
        },
        {
          name  = "ADMIN_LISTEN_PORT"
          value = tostring(var.weblogic_admin_port)
        },
        # Oracle DB接続情報（ホスト・ポート・DB名は非機密として環境変数に設定）
        {
          name  = "DB_HOST"
          value = aws_db_instance.oracle.address
        },
        {
          name  = "DB_PORT"
          value = "1521"
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "DB_USERNAME"
          value = var.db_username
        },
      ]

      # 機密情報はSecrets Managerから動的に取得（コンテナ内でも平文が見える点に注意）
      # JSON形式のシークレットから特定キーを "<arn>:<json-key>::" 形式で参照できる
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

      # ログドライバー設定（awslogs = CloudWatch Logsに送信）
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.weblogic.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "weblogic"
        }
      }

      # ヘルスチェック
      # WebLogicの起動には時間がかかるため startPeriod を長めに設定
      healthCheck = {
        command = [
          "CMD-SHELL",
          # curl が 200/302/401 を返せば起動完了とみなす
          "curl -s -o /dev/null -w '%%{http_code}' http://localhost:${tostring(var.weblogic_admin_port)}/console | grep -qE '^(200|302|401)$' || exit 1"
        ]
        interval    = 30
        timeout     = 10
        retries     = 5
        startPeriod = 180 # WebLogicは起動に3分程度かかる場合がある
      }
    }
  ])

  tags = local.common_tags
}

# =============================================================================
# ECSサービス（WebLogic）
# タスク定義をもとに指定数のコンテナを常時起動し、ALBと連携する
# =============================================================================

resource "aws_ecs_service" "weblogic" {
  name            = "${local.name_prefix}-weblogic"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.weblogic.arn
  desired_count   = var.weblogic_desired_count
  launch_type     = "FARGATE"

  # タスク定義変更時に既存タスクを強制的に再デプロイ
  force_new_deployment = true

  network_configuration {
    subnets          = module.vpc.private_subnet_ids   # プライベートAppサブネット
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false # プライベートサブネット＋NAT Gatewayを使用
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.weblogic_admin.arn
    container_name   = "weblogic"
    container_port   = var.weblogic_admin_port
  }

  # ALBリスナー・IAMロール・RDSが作成されてからサービスを起動する
  depends_on = [
    aws_lb_listener.http,
    aws_iam_role_policy_attachment.ecs_task_execution,
    aws_iam_role_policy.ecs_secrets_access,
    aws_db_instance.oracle,
    aws_secretsmanager_secret_version.rds_password,
    aws_secretsmanager_secret_version.weblogic_admin,
  ]

  tags = local.common_tags
}
