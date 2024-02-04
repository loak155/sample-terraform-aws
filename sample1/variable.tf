variable "domain" {
  description = "Route 53 で管理しているドメイン名"
  type        = string

   # FIXME: ドメイン名を入力
  default = "example.com"
}

# Route53 Hosted Zone
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone.html
data "aws_route53_zone" "main" {
  name         = var.domain
  private_zone = false
}

# ACM
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate.html
resource "aws_acm_certificate" "main" {
  domain_name = var.domain

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Route53 record
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record.html
resource "aws_route53_record" "validation" {
  depends_on = [aws_acm_certificate.main]

  zone_id = data.aws_route53_zone.main.id

  ttl = 60

  name    = tolist(aws_acm_certificate.main.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.main.domain_validation_options)[0].resource_record_type
  records = [tolist(aws_acm_certificate.main.domain_validation_options)[0].resource_record_value]
}

# ACM Validate
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation.html
resource "aws_acm_certificate_validation" "main" {
  certificate_arn = aws_acm_certificate.main.arn

  validation_record_fqdns = [aws_route53_record.validation.fqdn]
}

# Route53 record
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record.html
resource "aws_route53_record" "main" {
  type = "A"

  name    = var.domain
  zone_id = data.aws_route53_zone.main.id

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# ALB Listener
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener.html
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn

  certificate_arn = aws_acm_certificate.main.arn

  port     = "443"
  protocol = "HTTPS"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.id
  }
}

# ALB Listener Rule
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule.html
resource "aws_lb_listener_rule" "http_to_https" {
  listener_arn = aws_lb_listener.main.arn

  priority = 99

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values = [var.domain]
    }
  }
}

# Security Group Rule
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule.html
resource "aws_security_group_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id

  type = "ingress"

  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}