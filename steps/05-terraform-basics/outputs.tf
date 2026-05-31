# =============================================================================
# Step 5: 出力定義
# =============================================================================
# ※ 05-terragrunt-basics/outputs.tf と同一内容

output "bucket_name" {
  description = "S3バケット名"
  value       = module.s3.bucket_name
}

output "bucket_arn" {
  description = "S3バケットのARN"
  value       = module.s3.bucket_arn
}
