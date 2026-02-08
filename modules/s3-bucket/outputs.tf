# =============================================================================
# S3バケットモジュール - 出力値
# =============================================================================

# バケットのARN（他のリソースからの参照に使用）
output "bucket_arn" {
  description = "S3バケットのARN"
  value       = aws_s3_bucket.this.arn
}

# バケット名
output "bucket_name" {
  description = "S3バケットの名前"
  value       = aws_s3_bucket.this.id
}

# バケットのリージョン
output "bucket_region" {
  description = "S3バケットのリージョン"
  value       = aws_s3_bucket.this.region
}
