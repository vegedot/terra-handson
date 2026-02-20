# =============================================================================
# Secrets Manager - 機密情報の安全な管理
# =============================================================================
# パスワードなどの機密情報をTerraform状態ファイルやコード上に平文で持つことを避けるため、
# Secrets Managerに保存し、ECSタスク起動時に動的に注入します。
#
# 管理する情報:
#   1. RDS Oracle マスターパスワード（自動生成）
#   2. WebLogic 管理コンソール認証情報（変数から注入）
# =============================================================================

# RDSパスワードの自動生成（16文字、英数字+記号）
resource "random_password" "rds" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>?"
  # RDS Oracleで使えない記号を除外: @ / " ' ` ; space
}

# -----------------------------------------------------------------------------
# RDS Oracle 接続情報シークレット
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "rds_password" {
  name        = "${local.name_prefix}/rds/master-credentials"
  description = "RDS Oracle マスターユーザーの接続情報"

  tags = merge(
    { Name = "${local.name_prefix}-rds-credentials" },
    local.common_tags,
  )
}

# シークレットの値（RDS作成後にエンドポイントを含めて更新）
resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = aws_secretsmanager_secret.rds_password.id

  # JSON形式で保存することで、ECSコンテナが特定のキーを直接参照できる
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.rds.result
    engine   = "oracle"
    host     = module.rds.db_instance_address
    port     = tostring(module.rds.db_instance_port)
    dbname   = var.db_name
  })

  # RDSインスタンスが作成されてからエンドポイントを設定する
  depends_on = [module.rds]
}

# -----------------------------------------------------------------------------
# WebLogic 管理コンソール認証情報シークレット
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "weblogic_admin" {
  name        = "${local.name_prefix}/weblogic/admin-credentials"
  description = "WebLogic管理コンソールの認証情報"

  tags = merge(
    { Name = "${local.name_prefix}-weblogic-admin" },
    local.common_tags,
  )
}

resource "aws_secretsmanager_secret_version" "weblogic_admin" {
  secret_id = aws_secretsmanager_secret.weblogic_admin.id

  secret_string = jsonencode({
    username = var.weblogic_admin_username
    password = var.weblogic_admin_password
  })
}
