# 기본 VPC와 기본 서브넷은 직접 만들지 않고 조회만 한다.
data "aws_vpc" "main" {
  default = true
}

data "aws_subnet" "public" {
  for_each = var.public_subnet_names

  vpc_id = data.aws_vpc.main.id
  filter {
    name   = "tag:Name"
    values = [each.value]
  }
}

data "aws_subnet" "private" {
  for_each = var.private_subnet_cidrs

  vpc_id     = data.aws_vpc.main.id
  cidr_block = each.value
}

# ---- 프라이빗 라우팅: NAT 인스턴스, S3 Gateway 엔드포인트 ----
resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.main.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat.primary_network_interface_id
  }

  tags = {
    Name = "private-rtb"
  }
}

resource "aws_route_table_association" "private" {
  for_each = data.aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = data.aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "s3-gateway-endpoint"
  }
}

# ---- 보안 그룹 ----
resource "aws_security_group" "alb" {
  name        = "alb-security-group"
  description = "Application Load Balancer"
  vpc_id      = data.aws_vpc.main.id
}

resource "aws_security_group" "app" {
  name        = "app-security-group"
  description = "ECS Fargate application security group"
  vpc_id      = data.aws_vpc.main.id
}

resource "aws_security_group" "rds" {
  name        = "rds-security-group"
  description = "RDS MySQL security group"
  vpc_id      = data.aws_vpc.main.id
}

resource "aws_security_group" "redis" {
  name        = "redis-security-group"
  description = "ElastiCache Redis security group"
  vpc_id      = data.aws_vpc.main.id
}

resource "aws_security_group" "nat" {
  name        = "${var.project}-nat-instance-sg"
  description = "NAT instance for pangyeori private subnet outbound"
  vpc_id      = data.aws_vpc.main.id
}

locals {
  security_groups = {
    alb   = aws_security_group.alb.id
    app   = aws_security_group.app.id
    rds   = aws_security_group.rds.id
    redis = aws_security_group.redis.id
    nat   = aws_security_group.nat.id
  }
}

resource "aws_vpc_security_group_egress_rule" "all" {
  for_each = local.security_groups

  security_group_id = each.value
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = var.container_port
  to_port                      = var.container_port
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_app" {
  security_group_id            = aws_security_group.rds.id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_app" {
  for_each = toset(["6379", "6380"])

  security_group_id            = aws_security_group.redis.id
  ip_protocol                  = "tcp"
  from_port                    = tonumber(each.value)
  to_port                      = tonumber(each.value)
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_vpc_security_group_ingress_rule" "nat_from_app" {
  security_group_id            = aws_security_group.nat.id
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.app.id
}
