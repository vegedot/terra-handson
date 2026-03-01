# =============================================================================
# EC2インスタンスモジュール - 出力値
# =============================================================================

# インスタンスID
output "instance_id" {
  description = "EC2インスタンスのID"
  value       = aws_instance.this.id
}

# パブリックIPアドレス
output "public_ip" {
  description = "EC2インスタンスのパブリックIPアドレス"
  value       = aws_instance.this.public_ip
}

# プライベートIPアドレス
output "private_ip" {
  description = "EC2インスタンスのプライベートIPアドレス"
  value       = aws_instance.this.private_ip
}

# IAMロールARN
output "iam_role_arn" {
  description = "EC2インスタンスに関連付けられたIAMロールのARN"
  value       = aws_iam_role.this.arn
}

# インスタンスプロファイル名
output "instance_profile_name" {
  description = "EC2インスタンスプロファイルの名前"
  value       = aws_iam_instance_profile.this.name
}

# セキュリティグループID
output "security_group_id" {
  description = "作成されたセキュリティグループのID"
  value       = aws_security_group.this.id
}
