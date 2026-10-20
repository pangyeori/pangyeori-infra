variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "project" {
  description = "리소스 이름 접두사"
  type        = string
  default     = "pangyeori"
}

variable "environment" {
  description = "환경 이름 (S3 버킷, 시크릿 경로에 쓴다)"
  type        = string
  default     = "prod"
}

variable "container_port" {
  description = "앱 컨테이너 포트 (compute 스택도 이 값을 읽는다)"
  type        = number
  default     = 8080
}

# ---- 네트워크 ----
variable "private_subnet_cidrs" {
  description = "AZ별 프라이빗 서브넷 CIDR"
  type        = map(string)
  default = {
    a = "172.31.0.0/20"
    b = "172.31.16.0/20"
    c = "172.31.32.0/20"
  }
}

variable "public_subnet_names" {
  description = "AZ별 퍼블릭 서브넷의 Name 태그"
  type        = map(string)
  default = {
    a = "pangyeori-alb-public-1"
    b = "pangyeori-alb-public-2"
  }
}

# ---- NAT 인스턴스 ----
variable "nat_instance_type" {
  type    = string
  default = "t3.nano"
}

# ---- RDS ----
variable "db_username" {
  description = "RDS 마스터 사용자 이름 (생성 후 변경 불가)"
  type        = string
  default     = "pangyeori"
}

variable "db_password" {
  description = "RDS 마스터 비밀번호. 기존 DB는 null 로 두고, 변경은 무시한다."
  type        = string
  default     = null
  sensitive   = true
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "RDS 스토리지 크기(GB)"
  type        = number
  default     = 20
}

variable "db_availability_zone" {
  description = "RDS AZ. null 이면 기존 값을 유지한다."
  type        = string
  default     = null
}

# ---- S3 / ECR ----
variable "cors_allowed_origins" {
  description = "업로드 버킷에 직접 PUT/GET 할 수 있는 웹 출처"
  type        = list(string)
  default = [
    "http://localhost:3000",
    "http://localhost:3001",
    "https://pangyeori.com",
    "https://www.pangyeori.com",
    "https://pangyeori-fe.vercel.app",
  ]
}

variable "ecr_max_images" {
  description = "ECR에 보관할 최대 이미지 수"
  type        = number
  default     = 10
}

variable "ecr_untagged_expire_days" {
  description = "태그 없는 이미지를 보관할 일 수"
  type        = number
  default     = 1
}
