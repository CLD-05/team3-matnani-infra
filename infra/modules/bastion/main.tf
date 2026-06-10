# modules/bastion/main.tf

# 생성 리소스:
#   - data.aws_ami                   : ubuntu 이미지
#   - aws_iam_role                   : Bastion IAM Role
#   - aws_iam_role_policy_attachment : AmazonSSMManagedInstanceCore 연결
#   - aws_iam_instance_profile       : EC2에 IAM Role 부착용
#   - aws_security_group             : 인바운드 없음 (SSH 22번 닫음)
#                                      아웃바운드 전체 허용 (SSM 아웃바운드만 필요)
#   - aws_instance : Bastion EC2


# 접속 방법:
#   aws ssm start-session --target {instance_id} --profile team3-{name}


locals {
  name = "${var.team}-${var.project}-${var.env}-bastion"

  common_tags = {
    Team      = var.team
    Project   = var.project
    ManagedBy = "terraform"
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

# IAM
resource "aws_iam_role" "bastion" {
  name = "${local.name}-role"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name}-role"
  })
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${local.name}-profile"
  role = aws_iam_role.bastion.name
}


# Security Group
resource "aws_security_group" "bastion" {
  name   = "${local.name}-sg"
  description = "Bastion EC2 Security Group"
  vpc_id = var.vpc_id

  # 인바운드: 없음 (SSH 22번 닫음 — SSM은 아웃바운드만 필요)
  egress {
    description = "Allow all outbound traffic for SSM"
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
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  iam_instance_profile   = aws_iam_instance_profile.bastion.name
  vpc_security_group_ids = [aws_security_group.bastion.id]

  # 키페어 없음 — SSM으로만 접속
  user_data = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y mysql-client
    apt-get install -y redis-tools

    # AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install

    # kubectl (EKS private endpoint 진입용)
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/
  EOT

  tags = merge(local.common_tags, {
    Name = local.name
  })
}