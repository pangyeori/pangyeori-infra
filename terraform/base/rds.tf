# 퍼블릭(ALB) 서브넷을 뺀 기본 VPC 서브넷으로 구성한 서브넷 그룹.
data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

resource "aws_db_subnet_group" "main" {
  name        = "default-${data.aws_vpc.main.id}"
  description = "Created from the RDS Management Console"
  subnet_ids  = setsubtract(data.aws_subnets.all.ids, [for s in data.aws_subnet.public : s.id])
}

# RDS는 start/stop 워크플로우가 중지/시작만 하고 삭제하지 않는다.
resource "aws_db_instance" "main" {
  identifier = "${var.project}-db"

  engine         = "mysql"
  engine_version = "8.4.9"
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp2"
  storage_encrypted = true

  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = false
  availability_zone      = var.db_availability_zone

  backup_retention_period    = 0
  backup_window              = "17:53-18:23"
  maintenance_window         = "sun:18:56-sun:19:26"
  auto_minor_version_upgrade = true
  deletion_protection        = false
  copy_tags_to_snapshot      = true
  skip_final_snapshot        = true

  lifecycle {
    # 비밀번호는 Secrets Manager에서 관리하고, 마이너 버전은 AWS가 올릴 수 있다.
    ignore_changes = [password, engine_version]
  }
}
