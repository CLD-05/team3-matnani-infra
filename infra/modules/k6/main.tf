# modules/k6/main.tf
#
# 생성 리소스:
#   - aws_security_group : 인바운드 없음, 아웃바운드 전체 허용
#   - aws_instance       : k6 부하 테스트 EC2 (k6 설치 포함)
#
# IAM: bastion instance profile 재사용 (IAM Role 생성 권한 불필요)
#
# 접속 방법:
#   aws ssm start-session --target {instance_id} --profile team3-{name}


locals {
  name = "${var.team}-${var.project}-${var.env}-k6"

  common_tags = {
    Team        = var.team
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# bastion instance profile 참조
data "aws_iam_instance_profile" "bastion" {
  name = "${var.team}-${var.project}-${var.env}-bastion-profile"
}

# Security Group
resource "aws_security_group" "k6" {
  name        = "${local.name}-sg"
  description = "k6 Load Test EC2 Security Group"
  vpc_id      = var.vpc_id

  # 인바운드: 없음 (SSM은 아웃바운드만 필요)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name}-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# EC2
resource "aws_instance" "k6" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  iam_instance_profile   = data.aws_iam_instance_profile.bastion.name
  vpc_security_group_ids = [aws_security_group.k6.id]

  # 키페어 없음 — SSM으로만 접속
  user_data = <<-EOT
    #!/bin/bash
    apt-get update -y

    # k6 설치
    gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
      --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
    echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] \
      https://dl.k6.io/deb stable main" | tee /etc/apt/sources.list.d/k6.list
    apt-get update -y
    apt-get install -y k6
  EOT

  tags = merge(local.common_tags, {
    Name = local.name
  })

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}
