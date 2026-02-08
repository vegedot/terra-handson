# =============================================================================
# Step 2: 出力定義
# =============================================================================
# output ブロックで定義した値は以下で確認できる:
#   - terraform apply 実行後の画面出力
#   - terraform output コマンド
#   - 他のモジュールからの module.xxx.yyy 参照
# =============================================================================

# バケットのARN（Amazon Resource Name）
output "bucket_arn" {
  description = "作成されたS3バケットのARN"
  value       = aws_s3_bucket.this.arn
}

# バケット名
output "bucket_name" {
  description = "作成されたS3バケットの名前"
  value       = aws_s3_bucket.this.id
}

# バケットのリージョン
output "bucket_region" {
  description = "S3バケットが作成されたリージョン"
  value       = aws_s3_bucket.this.region
}

# 適用されたタグ一覧
output "bucket_tags" {
  description = "S3バケットに適用されたタグ"
  value       = aws_s3_bucket.this.tags_all
}
