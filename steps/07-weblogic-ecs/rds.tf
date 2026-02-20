# =============================================================================
# RDS Oracle SE2
# terraform-aws-modules/rds/aws を使用
# =============================================================================
# このモジュールは以下をまとめて作成します:
#   - RDS インスタンス本体
#   - DB サブネットグループ（create_db_subnet_group = true）
#   - DB パラメータグループ（create_db_parameter_group = true）
#   - DB オプショングループ（create_db_option_group = true）
# =============================================================================

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "${local.name_prefix}-oracle"

  # ---- エンジン設定 ----
  engine            = "oracle-se2"
  engine_version    = var.db_engine_version
  license_model     = "license-included"
  instance_class    = var.db_instance_class
  multi_az          = var.db_multi_az

  # ---- ストレージ設定 ----
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 2
  storage_type          = "gp3"
  storage_encrypted     = true

  # ---- 認証情報 ----
  # Oracle では db_name が SID（システム識別子）に相当する
  db_name  = var.db_name
  username = var.db_username
  password = random_password.rds.result
  port     = "1521"

  # ---- ネットワーク設定 ----
  vpc_security_group_ids = [module.rds_sg.security_group_id]
  publicly_accessible    = false

  # DBサブネットグループをモジュール内で作成
  create_db_subnet_group = true
  subnet_ids             = module.vpc.database_subnets

  # ---- パラメータグループ ----
  create_db_parameter_group = true
  family                    = "oracle-se2-19"
  # 追加パラメータが必要な場合は parameters リストに追加:
  # parameters = [
  #   { name = "nls_length_semantics", value = "CHAR" }
  # ]

  # ---- オプショングループ ----
  create_db_option_group = true
  major_engine_version   = "19"
  # WebLogicのJDBC Thin接続にはネイティブOracleクライアント不要なので追加オプションなし
  # options = []

  # ---- バックアップ設定 ----
  backup_retention_period  = 7
  backup_window            = "03:00-04:00"
  maintenance_window       = "sun:04:00-sun:05:00"
  delete_automated_backups = true

  # ---- 学習用設定（本番では変更推奨） ----
  skip_final_snapshot = true  # 削除時にスナップショットを取らない
  deletion_protection = false # 誤削除保護を無効

  tags = local.common_tags
}
