# =============================================================================
# 出力値
# terraform apply 後に表示される情報
# =============================================================================

# -----------------------------------------------------------------------------
# ECR（イメージのpush先）
# -----------------------------------------------------------------------------

output "ecr_repository_url" {
  description = "ECRリポジトリURL。WebLogicイメージのdocker push先として使用します"
  value       = aws_ecr_repository.weblogic.repository_url
}

# -----------------------------------------------------------------------------
# ECS
# -----------------------------------------------------------------------------

output "ecs_cluster_name" {
  description = "ECSクラスター名"
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "ECSサービス名"
  value       = aws_ecs_service.weblogic.name
}

output "cloudwatch_log_group" {
  description = "WebLogicコンテナのログ確認先（CloudWatch Logs）"
  value       = aws_cloudwatch_log_group.weblogic.name
}

# -----------------------------------------------------------------------------
# ALB（アクセスURL）
# -----------------------------------------------------------------------------

output "alb_dns_name" {
  description = "ALBのDNS名"
  value       = aws_lb.weblogic.dns_name
}

output "weblogic_console_url" {
  description = "WebLogic管理コンソールURL（ECSタスク起動後にアクセス可能）"
  value       = "http://${aws_lb.weblogic.dns_name}/console"
}

# -----------------------------------------------------------------------------
# RDS Oracle
# -----------------------------------------------------------------------------

output "rds_endpoint" {
  description = "RDS Oracleのエンドポイントホスト名（ECSコンテナ内からのみ到達可能）"
  value       = aws_db_instance.oracle.address
}

output "rds_port" {
  description = "RDS Oracleのポート番号"
  value       = aws_db_instance.oracle.port
}

output "rds_db_name" {
  description = "Oracle DB名（SID）"
  value       = aws_db_instance.oracle.db_name
}

output "rds_secret_arn" {
  description = "RDS接続情報が保存されたSecrets Manager ARN（パスワード確認はAWSコンソールで）"
  value       = aws_secretsmanager_secret.rds_password.arn
  sensitive   = true
}

# -----------------------------------------------------------------------------
# ネットワーク
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "nat_gateway_ip" {
  description = "NAT GatewayのパブリックIP（ファイアウォールのホワイトリスト登録に使用）"
  value       = aws_eip.nat.public_ip
}
