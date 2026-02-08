# =============================================================================
# VPCモジュール
# VPC、サブネット、インターネットゲートウェイ、ルートテーブルを作成する
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# VPC本体
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    {
      Name        = "${var.name}-vpc"
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

# パブリックサブネット - インターネットからアクセス可能なサブネット
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name        = "${var.name}-public-${var.availability_zones[count.index]}"
      Environment = var.environment
      Tier        = "public"
    },
    var.tags,
  )
}

# プライベートサブネット - インターネットから直接アクセスできないサブネット
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    {
      Name        = "${var.name}-private-${var.availability_zones[count.index]}"
      Environment = var.environment
      Tier        = "private"
    },
    var.tags,
  )
}

# インターネットゲートウェイ - VPCをインターネットに接続する
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name        = "${var.name}-igw"
      Environment = var.environment
    },
    var.tags,
  )
}

# パブリックルートテーブル - パブリックサブネット用のルーティング設定
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  # デフォルトルート: すべてのトラフィックをインターネットゲートウェイへ
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    {
      Name        = "${var.name}-public-rt"
      Environment = var.environment
    },
    var.tags,
  )
}

# パブリックサブネットとルートテーブルの関連付け
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
