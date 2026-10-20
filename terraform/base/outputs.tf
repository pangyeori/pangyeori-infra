output "rds_endpoint" {
  value = aws_db_instance.main.address
}

# start/stop 워크플로우가 NAT/RDS 를 시작/중지할 때 쓴다.
output "rds_identifier" {
  value = aws_db_instance.main.identifier
}

output "nat_instance_id" {
  value = aws_instance.nat.id
}

# ---- compute 스택이 읽는 값 ----
output "vpc_id" {
  value = data.aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "AZ 키 -> 퍼블릭 서브넷 ID (ALB)"
  value       = { for k, s in data.aws_subnet.public : k => s.id }
}

output "private_subnet_ids" {
  description = "AZ 키 -> 프라이빗 서브넷 ID (ECS, ElastiCache)"
  value       = { for k, s in data.aws_subnet.private : k => s.id }
}

output "security_group_ids" {
  value = {
    alb   = aws_security_group.alb.id
    app   = aws_security_group.app.id
    redis = aws_security_group.redis.id
  }
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "container_port" {
  value = var.container_port
}
