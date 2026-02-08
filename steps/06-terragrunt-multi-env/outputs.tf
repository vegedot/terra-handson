# =============================================================================
# Step 6: 出力定義
# =============================================================================

output "vpc_id" {
  description = "VPCのID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "パブリックサブネットのIDリスト"
  value       = module.vpc.public_subnet_ids
}

output "instance_id" {
  description = "EC2インスタンスのID"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "EC2インスタンスのパブリックIP"
  value       = module.ec2.public_ip
}
