# 최신 Amazon Linux 2023. AMI ID를 박아 두면 리전/시점에 묶이고 deprecated 된다.
data "aws_ami" "nat" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# EIP와 시작/중지는 start/stop 워크플로우가 맡는다. 여기서는 구성만 정의한다.
resource "aws_instance" "nat" {
  ami                    = data.aws_ami.nat.id
  instance_type          = var.nat_instance_type
  subnet_id              = data.aws_subnet.public["a"].id
  vpc_security_group_ids = [aws_security_group.nat.id]
  iam_instance_profile   = aws_iam_instance_profile.nat.name
  source_dest_check      = false

  metadata_options {
    http_tokens = "required"
  }

  user_data = <<-EOT
    #!/bin/bash
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    sysctl -p
    IFACE=$(ip -o -4 route show to default | awk '{print $5}')
    iptables -t nat -A POSTROUTING -o "$IFACE" -j MASQUERADE
    iptables-save > /etc/sysconfig/iptables
    systemctl enable --now iptables 2>/dev/null || true
  EOT

  tags = {
    Name = "${var.project}-nat-instance"
  }

  lifecycle {
    # AMI 갱신이나 user_data 서식 차이로 NAT를 재생성하지 않는다.
    ignore_changes = [ami, user_data]
  }
}
