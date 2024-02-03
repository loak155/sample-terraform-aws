# Task Definition
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition.html
resource "aws_ecs_task_definition" "main" {
  family = "microservices"

  requires_compatibilities = ["FARGATE"]

  cpu    = "256"
  memory = "512"

  network_mode = "awsvpc"

  container_definitions = <<EOL
[
  {
    "name": "nginx",
    "image": "nginx:1.14",
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ]
  }
]
EOL
}

# ECS Cluster
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster.html
resource "aws_ecs_cluster" "main" {
  name = "microservices"
}

# ELB Target Group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group.html
resource "aws_lb_target_group" "main" {
  name = "microservices"

  vpc_id = aws_vpc.main.id

  port        = 80
  protocol    = "HTTP"
  target_type = "ip"

  health_check {
    port = 80
    path = "/"
  }
}

# ALB Listener Rule
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule.html
resource "aws_lb_listener_rule" "main" {
  listener_arn = aws_lb_listener.main.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.id
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

# SecurityGroup
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group.html
resource "aws_security_group" "ecs" {
  name        = "microservices-ecs"
  description = "microservices ecs"

  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "microservices-ecs"
  }
}

# SecurityGroup Rule
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule.html
resource "aws_security_group_rule" "ecs" {
  security_group_id = aws_security_group.ecs.id

  type = "ingress"

  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  cidr_blocks = ["10.0.0.0/16"]
}

# ECS Service
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service.html
resource "aws_ecs_service" "main" {
  name = "microservices"

  depends_on = [aws_lb_listener_rule.main]

  cluster = aws_ecs_cluster.main.name

  launch_type = "FARGATE"

  desired_count = "1"

  task_definition = aws_ecs_task_definition.main.arn

  network_configuration {
    subnets         = [aws_subnet.private_1a.id, aws_subnet.private_1c.id]
    security_groups = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "nginx"
    container_port   = "80"
  }
}