output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "redis_endpoint" {
  value = aws_elasticache_serverless_cache.redis.endpoint[0].address
}

output "api_url" {
  value = "https://${local.api_record}"
}

# 워크플로우의 헬스체크 단계가 쓴다.
output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}
