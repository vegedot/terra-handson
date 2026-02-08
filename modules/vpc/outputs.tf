# =============================================================================
# VPCモジュール - 出力値
# =============================================================================

# VPC ID
output "vpc_id" {
  description = "作成されたVPCのID"
  value       = aws_vpc.this.id
}

# VPCのCIDRブロック
output "vpc_cidr_block" {
  description = "VPCのCIDRブロック"
  value       = aws_vpc.this.cidr_block
}

# パブリックサブネットのIDリスト
output "public_subnet_ids" {
  description = "パブリックサブネットのIDリスト"
  value       = aws_subnet.public[*].id
}

# プライベートサブネットのIDリスト
output "private_subnet_ids" {
  description = "プライベートサブネットのIDリスト"
  value       = aws_subnet.private[*].id
}

# インターネットゲートウェイのID
output "internet_gateway_id" {
  description = "インターネットゲートウェイのID"
  value       = aws_internet_gateway.this.id
}
