# =============================================================================
# Step 4: 出力定義
# =============================================================================
# モジュールの出力は module.<モジュール名>.<出力名> で参照する

# VPCモジュールの出力
output "vpc_id" {
  description = "VPCのID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "パブリックサブネットのIDリスト"
  value       = module.vpc.public_subnet_ids
}

# EC2モジュールの出力
output "instance_id" {
  description = "EC2インスタンスのID"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "EC2インスタンスのパブリックIP"
  value       = module.ec2.public_ip
}

# S3モジュールの出力
output "s3_bucket_name" {
  description = "S3バケット名"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "S3バケットのARN"
  value       = module.s3.bucket_arn
}
