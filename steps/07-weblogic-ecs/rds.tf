# =============================================================================
# RDS Oracle SE2（Standard Edition 2）
# =============================================================================
# WebLogicのデータソース接続先となるOracle DBを構築します。
#
# 構成:
#   - プライベートDBサブネット（ECSサブネットと分離）に配置
#   - ECSセキュリティグループからのみ1521番ポートへのアクセスを許可
#   - パスワードはSecrets Managerで管理（ランダム生成）
#   - ストレージ暗号化有効
#   - 自動バックアップ7日間保持
# =============================================================================

# DBサブネットグループ（RDS専用のプライベートサブネットを指定）
resource "aws_db_subnet_group" "oracle" {
  name        = "${local.name_prefix}-oracle-subnet-group"
  description = "RDS Oracle用DBサブネットグループ（マルチAZ対応）"
  subnet_ids  = aws_subnet.private_db[*].id

  tags = merge(
    { Name = "${local.name_prefix}-oracle-subnet-group" },
    local.common_tags,
  )
}

# DBパラメータグループ
# Oracle SE2 19cのデフォルト設定をベースに必要に応じてカスタマイズ
resource "aws_db_parameter_group" "oracle" {
  name        = "${local.name_prefix}-oracle-params"
  family      = "oracle-se2-19"
  description = "WebLogic用 Oracle SE2 19c パラメータグループ"

  tags = merge(
    { Name = "${local.name_prefix}-oracle-params" },
    local.common_tags,
  )
}

# DBオプショングループ
# WebLogicのJDBC Thin接続にはネイティブクライアントは不要なため、追加オプションなし
resource "aws_db_option_group" "oracle" {
  name                     = "${local.name_prefix}-oracle-options"
  engine_name              = "oracle-se2"
  major_engine_version     = "19"
  option_group_description = "WebLogic用 Oracle SE2 19c オプショングループ"

  tags = merge(
    { Name = "${local.name_prefix}-oracle-options" },
    local.common_tags,
  )
}

# RDS Oracle SE2 インスタンス本体
resource "aws_db_instance" "oracle" {
  identifier = "${local.name_prefix}-oracle"

  # エンジン設定
  engine         = "oracle-se2"
  engine_version = var.db_engine_version
  license_model  = "license-included" # SE2はライセンス込みを選択

  # インスタンス設定
  instance_class = var.db_instance_class
  multi_az       = var.db_multi_az

  # ストレージ設定
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 2 # Auto Scalingの上限
  storage_type          = "gp3"
  storage_encrypted     = true # 保存データの暗号化（必須推奨）

  # 認証情報
  # db_name は Oracle の SID（システム識別子）に相当します
  db_name  = var.db_name
  username = var.db_username
  password = random_password.rds.result

  # ネットワーク設定
  db_subnet_group_name   = aws_db_subnet_group.oracle.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false # プライベートサブネット内に閉じる

  # パラメータ・オプション
  parameter_group_name = aws_db_parameter_group.oracle.name
  option_group_name    = aws_db_option_group.oracle.name

  # バックアップ設定
  backup_retention_period  = 7           # 7日間バックアップ保持
  backup_window            = "03:00-04:00"
  maintenance_window       = "sun:04:00-sun:05:00"
  delete_automated_backups = true

  # 学習用の設定（本番環境では変更を推奨）
  skip_final_snapshot = true  # 削除時にスナップショットを取らない（本番ではfalse推奨）
  deletion_protection = false # 誤削除保護を無効（本番ではtrue推奨）

  tags = merge(
    { Name = "${local.name_prefix}-oracle" },
    local.common_tags,
  )
}
