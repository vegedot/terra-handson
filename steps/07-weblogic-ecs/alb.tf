# =============================================================================
# Application Load Balancer (Internal)
# terraform-aws-modules/alb/aws を使用
# =============================================================================
# インターネット非公開のPOC構成:
#   - Internal ALB をプライベートサブネットに配置
#   - 踏み台EC2からのみアクセス可能（VPC CIDR内に限定）
#   - 踏み台 → Internal ALB → ECS WebLogic の経路
# =============================================================================

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name     = "${local.name_prefix}-alb"
  vpc_id   = module.vpc.vpc_id
  internal = true # インターネット非公開（Internal ALB）

  # Internal ALB はプライベートサブネットに配置
  subnets = module.vpc.private_subnets

  # ALBのセキュリティグループ: VPC内からのHTTPのみ許可（踏み台EC2からのアクセス）
  security_group_ingress_rules = {
    http_from_vpc = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP from VPC internal only"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }
  security_group_egress_rules = {
    vpc = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "weblogic"
      }
    }
  }

  target_groups = {
    weblogic = {
      name             = "${local.name_prefix}-wl-tg"
      protocol         = "HTTP"
      port             = var.weblogic_admin_port
      target_type      = "ip"
      create_attachment = false

      health_check = {
        enabled             = true
        healthy_threshold   = 2
        unhealthy_threshold = 5
        timeout             = 10
        interval            = 30
        path                = "/console"
        matcher             = "200,302,401"
      }
    }
  }

  tags = local.common_tags
}
