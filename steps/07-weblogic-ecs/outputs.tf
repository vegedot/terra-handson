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
  value       = module.ecs_cluster.cluster_name
}

output "ecs_cluster_arn" {
  description = "ECSクラスターARN"
  value       = module.ecs_cluster.cluster_arn
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
  value       = module.alb.dns_name
}

output "weblogic_console_url" {
  description = "WebLogic管理コンソールURL（ECSタスク起動後にアクセス可能）"
  value       = "http://${module.alb.dns_name}/console"
}

# -----------------------------------------------------------------------------
# RDS Oracle
# -----------------------------------------------------------------------------

output "rds_endpoint" {
  description = "RDS Oracleのエンドポイントホスト名（ECSコンテナ内からのみ到達可能）"
  value       = module.rds.db_instance_address
}

output "rds_port" {
  description = "RDS Oracleのポート番号"
  value       = module.rds.db_instance_port
}

output "rds_db_name" {
  description = "Oracle DB名（SID）"
  value       = module.rds.db_instance_name
}

output "rds_secret_arn" {
  description = "RDS接続情報が保存されたSecrets Manager ARN（パスワード確認はAWSコンソールで）"
  value       = aws_secretsmanager_secret.rds_password.arn
  sensitive   = true
}

# -----------------------------------------------------------------------------
# 踏み台EC2
# -----------------------------------------------------------------------------

output "bastion_instance_id" {
  description = "踏み台EC2のインスタンスID（SSM接続コマンドで使用）"
  value       = aws_instance.bastion.id
}

output "bastion_connect_command" {
  description = "踏み台へのRDP用SSMポートフォワーディングコマンド"
  value       = "aws ssm start-session --target ${aws_instance.bastion.id} --document-name AWS-StartPortForwardingSession --parameters '{\"portNumber\":[\"3389\"],\"localPortNumber\":[\"13389\"]}'"
}

output "weblogic_internal_url" {
  description = "踏み台EC2のブラウザから開くWebLogic管理コンソールURL（Internal ALB経由）"
  value       = "http://${module.alb.dns_name}/console"
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
  value       = module.vpc.nat_public_ips[0]
}
