# =============================================================================
# Application Load Balancer (ALB)
# インターネットからWebLogicへのHTTPルーティングを提供
# =============================================================================

# ALB本体（パブリックサブネットに配置）
resource "aws_lb" "weblogic" {
  name               = "${local.name_prefix}-alb"
  internal           = false # インターネット向けALB
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnet_ids # マルチAZのパブリックサブネット

  # 学習用はfalse（本番ではtrue推奨）
  enable_deletion_protection = false

  tags = merge(
    { Name = "${local.name_prefix}-alb" },
    local.common_tags,
  )
}

# ターゲットグループ（WebLogic管理サーバー向け）
# Fargateは動的IPを持つため、target_type = "ip" を指定する必要がある
resource "aws_lb_target_group" "weblogic_admin" {
  name        = "${local.name_prefix}-wl-tg"
  port        = var.weblogic_admin_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip" # ECS Fargateには "ip" が必須

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
    path                = "/console"
    port                = "traffic-port"
    protocol            = "HTTP"
    # WebLogicコンソールは 200 (表示) または 302/401 (認証リダイレクト) を返す
    matcher = "200,302,401"
  }

  tags = merge(
    { Name = "${local.name_prefix}-wl-tg" },
    local.common_tags,
  )
}

# HTTPリスナー（ポート80 → WebLogicへ転送）
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.weblogic.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.weblogic_admin.arn
  }
}
