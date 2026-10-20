# 서버를 켜고 끌 때 만들고 지우는 리소스. 켜기: terraform apply / 끄기: terraform destroy
# RDS와 NAT 인스턴스의 시작/중지는 워크플로우(또는 CLI)가 맡는다.

# ---- ElastiCache Serverless (Valkey) ----
resource "aws_elasticache_serverless_cache" "redis" {
  name                 = "${var.project}-redis"
  engine               = "valkey"
  major_engine_version = var.redis_major_engine_version

  security_group_ids = concat([local.base.security_group_ids.redis], [for g in data.aws_security_group.redis_extra : g.id])
  subnet_ids         = local.private_subnet_ids
}

# ---- ALB ----
resource "aws_lb" "main" {
  name               = "${var.project}-alb"
  load_balancer_type = "application"
  internal           = false
  ip_address_type    = "ipv4"
  security_groups    = [local.base.security_group_ids.alb]
  subnets            = local.public_subnet_ids
}

resource "aws_lb_target_group" "app" {
  name             = "${var.project}-tg"
  vpc_id           = local.base.vpc_id
  protocol         = "HTTP"
  port             = local.base.container_port
  target_type      = "ip"
  ip_address_type  = "ipv4"
  protocol_version = "HTTP1"

  health_check {
    protocol            = "HTTP"
    port                = "traffic-port"
    path                = var.health_check_path
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  protocol          = "HTTPS"
  port              = 443
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.main.arn
  protocol          = "HTTP"
  port              = 80

  default_action {
    type = "redirect"
    redirect {
      protocol    = "HTTPS"
      port        = "443"
      host        = "#{host}"
      path        = "/#{path}"
      query       = "#{query}"
      status_code = "HTTP_301"
    }
  }
}

# ---- Route53 ----
resource "aws_route53_record" "api" {
  zone_id = var.hosted_zone_id
  name    = local.api_record
  type    = "A"

  # 기존 stop 워크플로우는 레코드를 지우지 않으므로, 남아 있어도 덮어쓴다.
  allow_overwrite = true

  alias {
    name                   = "dualstack.${aws_lb.main.dns_name}"
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# ---- ECS Service ----
resource "aws_ecs_service" "app" {
  name            = "${var.project}-service"
  cluster         = local.base.ecs_cluster_name
  task_definition = "${data.aws_ecs_task_definition.latest.family}:${data.aws_ecs_task_definition.latest.revision}"
  desired_count   = var.desired_count

  scheduling_strategy   = "REPLICA"
  wait_for_steady_state = true

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 0
  }

  network_configuration {
    subnets          = local.private_subnet_ids
    security_groups  = [local.base.security_group_ids.app]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = local.container_name
    container_port   = local.base.container_port
  }

  health_check_grace_period_seconds  = 120
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  enable_ecs_managed_tags            = true
  availability_zone_rebalancing      = "ENABLED"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [
    aws_lb_listener.https,
    aws_elasticache_serverless_cache.redis,
  ]
}
