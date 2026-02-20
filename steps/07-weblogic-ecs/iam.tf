# =============================================================================
# IAMロール（ECS用）
# =============================================================================
# ECSには2種類のIAMロールが必要:
#
# 1. タスク実行ロール (execution_role):
#    ECSエージェント（コントロールプレーン）が使用するロール
#    - ECRからのイメージpull
#    - CloudWatch Logsへのログ書き込み
#    - Secrets Managerからの機密情報取得
#
# 2. タスクロール (task_role):
#    コンテナ内のアプリケーションが使用するロール
#    - アプリがAWS SDKでAWSサービスを呼び出す際に使用
#    - 今回はWebLogicがAWSサービスを直接呼び出さないため最小限
# =============================================================================

# -----------------------------------------------------------------------------
# タスク実行ロール
# -----------------------------------------------------------------------------

resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.name_prefix}-ecs-exec-role"
  description = "ECSタスク実行ロール: ECR pull / CloudWatch Logs / Secrets Manager"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

# AWSマネージドポリシーをアタッチ
# ECRからのイメージpull + CloudWatch Logsへの書き込みが含まれる
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Secrets Managerへのアクセスを追加
# ECSタスク起動時にWebLogicのパスワードとDBパスワードを取得するために必要
resource "aws_iam_role_policy" "ecs_secrets_access" {
  name = "${local.name_prefix}-ecs-secrets-access"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [
          aws_secretsmanager_secret.rds_password.arn,
          aws_secretsmanager_secret.weblogic_admin.arn,
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# タスクロール
# コンテナ内アプリ（WebLogic）用。今後AWSサービス連携が必要になった場合はここにポリシーを追加する
# -----------------------------------------------------------------------------

resource "aws_iam_role" "ecs_task" {
  name        = "${local.name_prefix}-ecs-task-role"
  description = "ECSタスクロール: コンテナ内アプリケーション用"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}
