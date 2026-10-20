# base 스택이 만든 값은 이름으로 다시 찾지 않고 base 출력에서 읽는다.
data "terraform_remote_state" "base" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "pangyeori/base.tfstate" # base/versions.tf 의 backend key 와 같아야 한다
    region = var.region
  }
}

locals {
  base = data.terraform_remote_state.base.outputs

  private_subnet_ids = [for k in var.private_subnet_keys : local.base.private_subnet_ids[k]]
  public_subnet_ids  = values(local.base.public_subnet_ids)

  container_name = coalesce(var.container_name, "${var.project}-backend")
  api_record     = "${var.api_subdomain}.${var.domain_name}"
}

# 태스크 정의는 앱 CI 가 소유한다. 서비스는 항상 최신 ACTIVE 리비전(<project>-task)을 쓴다.
data "aws_ecs_task_definition" "latest" {
  task_definition = "${var.project}-task"
}

# CloudShell 접속용으로 ElastiCache 에 붙어 있는 SG. Terraform 이 만든 것이 아니어서 이름으로 찾는다.
data "aws_security_group" "redis_extra" {
  for_each = toset(var.redis_extra_sg_names)

  name   = each.value
  vpc_id = local.base.vpc_id
}
