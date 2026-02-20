# =============================================================================
# ネットワーク構成
# =============================================================================
# 既存のVPCモジュールを使用してVPC・パブリックサブネット・アプリサブネットを作成し、
# このファイルではDBサブネットとNAT Gatewayをモジュール外で追加します。
#
# サブネット構成:
#   パブリック     (10.0.1.x / 10.0.2.x)  ← ALB
#   プライベートApp (10.0.10.x / 10.0.20.x) ← ECS Fargate (WebLogic)
#   プライベートDB  (10.0.30.x / 10.0.40.x) ← RDS Oracle
# =============================================================================

# VPCモジュール: VPC本体・パブリックサブネット・アプリサブネット・IGWを作成
module "vpc" {
  source = "../../modules/vpc"

  name                 = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_app_subnet_cidrs
  availability_zones   = var.availability_zones
  environment          = var.environment
  tags                 = local.common_tags
}

# =============================================================================
# DBサブネット（RDS Oracle専用）
# AppサブネットとDBサブネットを分けることで、
# ECSからのアクセスのみ許可するセキュリティグループ制御が明確になる
# =============================================================================

resource "aws_subnet" "private_db" {
  count = length(var.private_db_subnet_cidrs)

  vpc_id            = module.vpc.vpc_id
  cidr_block        = var.private_db_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    {
      Name = "${local.name_prefix}-private-db-${var.availability_zones[count.index]}"
      Tier = "private-db"
    },
    local.common_tags,
  )
}

# =============================================================================
# NAT Gateway
# プライベートサブネット内のECS FargateがECRからイメージをpullしたり、
# Secrets ManagerやCloudWatch Logsに通信するために必要
#
# 注意: NAT Gatewayには1時間あたりの料金と転送量課金が発生します
#       HA構成（本番）では各AZにNAT Gatewayを配置しますが、
#       学習目的では1つのみ作成します
# =============================================================================

# NAT Gateway用の固定パブリックIP
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(
    { Name = "${local.name_prefix}-nat-eip" },
    local.common_tags,
  )

  depends_on = [module.vpc]
}

# NAT Gateway本体（パブリックサブネットに配置する必要がある）
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = module.vpc.public_subnet_ids[0]

  tags = merge(
    { Name = "${local.name_prefix}-nat" },
    local.common_tags,
  )

  depends_on = [module.vpc]
}

# =============================================================================
# プライベートルートテーブル
# AppサブネットとDBサブネット共通で使用
# アウトバウンドトラフィックをNAT Gatewayへルーティング
# （DBサブネットからのアウトバウンドは通常不要だが、パッチ適用時などに必要になる場合がある）
# =============================================================================

resource "aws_route_table" "private" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = merge(
    { Name = "${local.name_prefix}-private-rt" },
    local.common_tags,
  )
}

# Appサブネット（ECS）とプライベートルートテーブルの関連付け
resource "aws_route_table_association" "private_app" {
  count = length(module.vpc.private_subnet_ids)

  subnet_id      = module.vpc.private_subnet_ids[count.index]
  route_table_id = aws_route_table.private.id
}

# DBサブネット（RDS）とプライベートルートテーブルの関連付け
resource "aws_route_table_association" "private_db" {
  count = length(aws_subnet.private_db)

  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private.id
}
