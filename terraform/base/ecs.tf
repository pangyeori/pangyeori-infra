# 클러스터는 서버를 꺼도 유지한다. 서비스는 compute 스택에서 만든다.
# 태스크 정의는 앱 CI(deploy-prod)가 소유하므로 관리하지 않는다.
resource "aws_ecs_cluster" "main" {
  name = "${var.project}-cluster"

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }
}
