# =============================================================================
# 踏み台EC2 (Windows Server 2022)
# SSM Session Manager でインターネット非公開のまま接続する
# =============================================================================
# 接続方法（キーペア不要・インバウンドポート不要）:
#
#   RDP接続:
#     aws ssm start-session \
#       --target $(terraform output -raw bastion_instance_id) \
#       --document-name AWS-StartPortForwardingSession \
#       --parameters '{"portNumber":["3389"],"localPortNumber":["13389"]}'
#     → localhost:13389 に RDP クライアントで接続
#
#   Windowsパスワード確認（初回のみ）:
#     aws ec2 get-password-data \
#       --instance-id $(terraform output -raw bastion_instance_id) \
#       --region ap-northeast-1
# =============================================================================

# 最新の Windows Server 2022 AMI を自動取得
data "aws_ami" "windows_2022" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-Japanese-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# =============================================================================
# SSM用 IAMロール
# EC2インスタンスがSSM Session Managerで管理されるために必要
# =============================================================================

resource "aws_iam_role" "bastion" {
  name        = "${local.name_prefix}-bastion-role"
  description = "Bastion EC2 - SSM Session Manager management"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

# AmazonSSMManagedInstanceCore: SSM Session Managerの動作に必要な最小権限
resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${local.name_prefix}-bastion-profile"
  role = aws_iam_role.bastion.name

  tags = local.common_tags
}

# =============================================================================
# 踏み台EC2インスタンス
# =============================================================================

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.windows_2022.id
  instance_type = var.bastion_instance_type

  # プライベートサブネットに配置（インターネット非公開）
  subnet_id = module.vpc.private_subnets[0]

  vpc_security_group_ids = [module.bastion_sg.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.name

  # SSM Session Manager で管理するためキーペア・パブリックIPは不要
  associate_public_ip_address = false

  # EBSルートボリューム設定
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50 # Windows Server の最小推奨サイズ
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(
    { Name = "${local.name_prefix}-bastion" },
    local.common_tags,
  )
}
