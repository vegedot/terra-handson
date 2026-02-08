# =============================================================================
# Step 3: 出力定義
# =============================================================================

# ステートバケット名（backend設定で使用する）
output "state_bucket_name" {
  description = "Terraformステートを保存するS3バケット名"
  value       = aws_s3_bucket.terraform_state.id
}

# ステートバケットのARN
output "state_bucket_arn" {
  description = "ステートバケットのARN"
  value       = aws_s3_bucket.terraform_state.arn
}

# ロックテーブル名（backend設定で使用する）
output "lock_table_name" {
  description = "ステートロック用のDynamoDBテーブル名"
  value       = aws_dynamodb_table.terraform_lock.name
}
