# 현재 AWS 계정 정보 (Account ID) 가져오기
data "aws_caller_identity" "current" {}

# infra/outputs.tf 대신 AWS에서 EKS 클러스터 정보를 직접 조회합니다!
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

locals {
  # EKS 데이터 소스에서 필요한 정보 추출
  cluster_name     = data.aws_eks_cluster.cluster.name
  cluster_endpoint = data.aws_eks_cluster.cluster.endpoint
  cluster_ca       = data.aws_eks_cluster.cluster.certificate_authority[0].data
  vpc_id           = data.aws_eks_cluster.cluster.vpc_config[0].vpc_id
  oidc_issuer_url  = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer

  # OIDC 문자열을 용도에 맞게 가공
  oidc_provider_host = replace(local.oidc_issuer_url, "https://", "")
  oidc_provider_arn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_provider_host}"

  common_tags = {
    Team      = var.team
    Project   = var.project
    ManagedBy = "terraform"
  }
}


# 2. IRSA Role 4개


# EBS CSI — Prometheus PV 생성용
resource "aws_iam_role" "ebs_csi" {
  name                 = "${var.team}-${var.project}-ebs-csi-role"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider_host}:aud" = "sts.amazonaws.com" 
          "${local.oidc_provider_host}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
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
      Principal = { Federated = local.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider_host}:aud" = "sts.amazonaws.com" 
          "${local.oidc_provider_host}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
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
      Principal = { Federated = local.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider_host}:aud" = "sts.amazonaws.com" 
          "${local.oidc_provider_host}:sub" = "system:serviceaccount:external-secrets:external-secrets-sa"
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
      Action   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
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
      Principal = { Federated = local.oidc_provider_arn } 
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider_host}:aud" = "sts.amazonaws.com" 
          "${local.oidc_provider_host}:sub" = "system:serviceaccount:kube-system:external-dns"
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
      { Effect = "Allow", Action = ["route53:ChangeResourceRecordSets"], Resource = "arn:aws:route53:::hostedzone/${var.route53_zone_id}" },
      { Effect = "Allow", Action = ["route53:ListHostedZones", "route53:ListResourceRecordSets"], Resource = "*" }
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
  
  vpc_id                  = local.vpc_id  # vpc_id 전달
  
  alb_controller_role_arn = aws_iam_role.alb_controller.arn
  eso_role_arn            = aws_iam_role.eso.arn
  external_dns_role_arn   = aws_iam_role.external_dns.arn
  grafana_admin_password  = var.grafana_admin_password
}