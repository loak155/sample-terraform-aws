# SecurityGroup
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group.html
resource "aws_security_group" "alb" {
  name        = "microservices-alb"
  description = "microservices alb"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "microservices-alb"
  }
}

# SecurityGroup Rule
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule.html
resource "aws_security_group_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  type = "ingress"

  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}

# ALB
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lb.html
resource "aws_lb" "main" {
  load_balancer_type = "application"
  name               = "microservices"

  security_groups = [aws_security_group.alb.id]
  subnets         = [aws_subnet.public_1a.id, aws_subnet.public_1c.id]
}

# Listener
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener.html
resource "aws_lb_listener" "main" {
  port              = "80"
  protocol          = "HTTP"

  load_balancer_arn = "${aws_lb.main.arn}"

  default_action {
    type             = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "ok"
    }
  }
}