# 1. infra state 참조 (클러스터 뼈대 정보 가져오기)
data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "tfstate-lionkdt5-team3"
    key    = "team3/dev/infra/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

locals {
  cluster_name     = data.terraform_remote_state.infra.outputs.cluster_name
  cluster_endpoint = data.terraform_remote_state.infra.outputs.cluster_endpoint
  cluster_ca       = data.terraform_remote_state.infra.outputs.cluster_ca
  oidc_issuer_url  = data.terraform_remote_state.infra.outputs.oidc_issuer_url

  common_tags = {
    Team      = var.team
    Project   = var.project
    ManagedBy = "terraform"
  }
}

# 2. IRSA Role 4개 생성 (권한 경계 필수 부착됨)

# EBS CSI — Prometheus PV 생성용
resource "aws_iam_role" "ebs_csi" {
  name                 = "${var.team}-${var.project}-ebs-csi-role"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_issuer_url }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer_url}:aud" = "sts.amazonaws.com"
          "${local.oidc_issuer_url}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })

  tags = merge(local.common_tags, { Name = "${var.team}-${var.project}-ebs-csi-role" })
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ALB Controller — ALB 생성/수정/삭제용
resource "aws_iam_policy" "alb_controller" {
  name   = "${var.team}-${var.project}-alb-controller-policy"
  policy = file("${path.module}/policies/alb-controller-policy.json")
  tags   = local.common_tags
}

resource "aws_iam_role" "alb_controller" {
  name                 = "${var.team}-${var.project}-alb-controller-role"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_issuer_url }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer_url}:aud" = "sts.amazonaws.com"
          "${local.oidc_issuer_url}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })

  tags = merge(local.common_tags, { Name = "${var.team}-${var.project}-alb-controller-role" })
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

# ESO — SSM Parameter Store 읽기용
resource "aws_iam_role" "eso" {
  name                 = "${var.team}-${var.project}-eso-role"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_issuer_url }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer_url}:aud" = "sts.amazonaws.com"
          "${local.oidc_issuer_url}:sub" = "system:serviceaccount:external-secrets:external-secrets-sa"
        }
      }
    }]
  })

  tags = merge(local.common_tags, { Name = "${var.team}-${var.project}-eso-role" })
}

resource "aws_iam_role_policy" "eso_ssm" {
  name = "${var.team}-${var.project}-eso-ssm"
  role = aws_iam_role.eso.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ]
      Resource = "arn:aws:ssm:ap-northeast-2:*:parameter/matnani/dev/*"
    }]
  })
}

# ExternalDNS — Route53 레코드 자동 등록용
resource "aws_iam_role" "external_dns" {
  name                 = "${var.team}-${var.project}-external-dns-role"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_issuer_url }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer_url}:aud" = "sts.amazonaws.com"
          "${local.oidc_issuer_url}:sub" = "system:serviceaccount:kube-system:external-dns"
        }
      }
    }]
  })

  tags = merge(local.common_tags, { Name = "${var.team}-${var.project}-external-dns-role" })
}

resource "aws_iam_role_policy" "external_dns_route53" {
  name = "${var.team}-${var.project}-external-dns-route53"
  role = aws_iam_role.external_dns.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets"]
        Resource = "arn:aws:route53:::hostedzone/${var.route53_zone_id}"
      },
      {
        Effect   = "Allow"
        Action   = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ]
        Resource = "*"
      }
    ]
  })
}

# 3. modules/addons 호출
module "addons" {
  source = "../../../modules/addons" 

  team                    = var.team
  project                 = var.project
  environment             = var.env  
  cluster_name            = local.cluster_name
  cluster_endpoint        = local.cluster_endpoint
  cluster_ca_certificate  = local.cluster_ca  
  
  alb_controller_role_arn = aws_iam_role.alb_controller.arn
  eso_role_arn            = aws_iam_role.eso.arn
  external_dns_role_arn   = aws_iam_role.external_dns.arn
  grafana_admin_password  = var.grafana_admin_password
}