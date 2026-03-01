# =============================================================================
# EC2インスタンスモジュール
# EC2インスタンスとセキュリティグループを作成する
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

# セキュリティグループ - インスタンスへのネットワークアクセスを制御する
resource "aws_security_group" "this" {
  name        = "${var.name}-sg"
  description = "${var.name} のセキュリティグループ"
  vpc_id      = var.vpc_id

  # SSH接続を許可（ポート22）
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  # HTTP接続を許可（ポート80）
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # すべてのアウトバウンドトラフィックを許可
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.name}-sg"
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

# IAMロール - EC2インスタンスが他のAWSサービスにアクセスするための権限
resource "aws_iam_role" "this" {
  name = "${var.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.name}-role"
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

# IAMロールにマネージドポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(var.iam_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

# インスタンスプロファイル - IAMロールをEC2インスタンスに関連付ける
resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-profile"
  role = aws_iam_role.this.name

  tags = merge(
    {
      Name        = "${var.name}-profile"
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

# EC2インスタンス本体
resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  iam_instance_profile        = aws_iam_instance_profile.this.name
  associate_public_ip_address = var.associate_public_ip_address

  tags = merge(
    {
      Name        = var.name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}
