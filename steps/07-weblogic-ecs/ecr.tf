# =============================================================================
# ECR (Elastic Container Registry)
# WebLogicコンテナイメージの保管・配信リポジトリ
# =============================================================================
# 使い方:
#   1. terraform apply でリポジトリを作成
#   2. outputs.ecr_repository_url でリポジトリURIを確認
#   3. WebLogicイメージをビルドしてECRにpush（README.md参照）
#   4. terraform apply -var="weblogic_image_uri=<URI>:<TAG>" で ECS にデプロイ
# =============================================================================

resource "aws_ecr_repository" "weblogic" {
  name                 = "${local.name_prefix}-weblogic"
  image_tag_mutability = "MUTABLE"

  # プッシュ時に自動でセキュリティスキャンを実行
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    { Name = "${local.name_prefix}-weblogic" },
    local.common_tags,
  )
}

# ライフサイクルポリシー: 古いイメージを自動削除してストレージコストを削減
# 直近10件のイメージのみ保持（開発環境向け）
resource "aws_ecr_lifecycle_policy" "weblogic" {
  repository = aws_ecr_repository.weblogic.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "直近10件のイメージのみ保持"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
