variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "project" {
  description = "리소스 이름 접두사. base 스택의 project 와 같아야 한다."
  type        = string
  default     = "pangyeori"
}

variable "state_bucket" {
  description = "base 스택의 state 가 있는 S3 버킷"
  type        = string
}

variable "private_subnet_keys" {
  description = "ECS/ElastiCache 를 둘 AZ 키 (base 의 private_subnet_ids 키)"
  type        = list(string)
  default     = ["a", "b"]
}

# ---- 도메인 / 인증서 ----
variable "domain_name" {
  type    = string
  default = "pangyeori.com"
}

variable "api_subdomain" {
  description = "API 레코드의 서브도메인 (api -> api.<domain_name>)"
  type        = string
  default     = "api"
}

variable "hosted_zone_id" {
  description = "domain_name 의 Route53 호스팅 존 ID"
  type        = string
}

variable "certificate_arn" {
  description = "ALB HTTPS 리스너용 ACM 인증서 ARN"
  type        = string
}

variable "ssl_policy" {
  description = "ALB HTTPS 리스너의 TLS 정책"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09"
}

# ---- 앱 ----
variable "container_name" {
  description = "컨테이너 이름. null 이면 <project>-backend. 백엔드 CI 의 ECS_CONTAINER_NAME 과 같아야 한다."
  type        = string
  default     = null
}

variable "health_check_path" {
  description = "ALB 타겟 그룹의 헬스체크 경로"
  type        = string
  default     = "/actuator/health"
}

variable "desired_count" {
  type    = number
  default = 1
}

# ---- ElastiCache ----
variable "redis_major_engine_version" {
  type    = string
  default = "9"
}

variable "redis_extra_sg_names" {
  description = "ElastiCache 에 추가로 붙일 SG 이름 (현재 CloudShell 접속용)"
  type        = list(string)
  default     = ["cloudshell-elasticache-pangyeori-redis"]
}
