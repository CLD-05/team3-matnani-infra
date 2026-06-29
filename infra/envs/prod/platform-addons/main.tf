# infra/envs/prod/platform-addons/main.tf

# 생성 리소스:
#   - data.terraform_remote_state    : prod/infra state에서 클러스터 정보 참조
#                                      cluster_name, cluster_endpoint, cluster_ca, oidc_issuer_url
#
#   - aws_iam_role (ebs-csi)         : EBS CSI Driver IRSA Role
#     -> ebs-csi-controller-sa ServiceAccount에 EBS 볼륨 생성/마운트 권한 부여
#     -> Prometheus/Grafana PV 생성 시 사용
#
#   - aws_iam_role (alb-controller)  : ALB Controller IRSA Role
#     -> aws-load-balancer-controller ServiceAccount에 ALB 생성/수정/삭제 권한 부여
#     -> Ingress 감지 후 ALB 자동 생성
#
#   - aws_iam_role (eso)             : External Secrets Operator IRSA Role
#     -> external-secrets-sa ServiceAccount에 SSM 읽기 권한 부여
#     -> /matnani/prod/* 경로 한정 (dev와 분리)
#
#   - aws_iam_role (external-dns)    : ExternalDNS IRSA Role
#     -> external-dns ServiceAccount에 Route53 레코드 변경 권한 부여
#     -> prod: upsert-only 정책 (실수 삭제 차단)
#
#   - module.addons                  : Helm 차트 설치
#     -> ArgoCD, ALB Controller, ESO, Prometheus+Grafana
#     -> ExternalDNS, metrics-server, KEDA

# 현재 AWS 계정 정보 가져오기
data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "grafana_password" {
  name            = "/team3/matnani/prod/grafana-password"
  with_decryption = true
}

data "aws_ssm_parameter" "slack_webhook_url" {
  name            = "/team3/matnani/prod/monitoring/slack-webhook"
  with_decryption = true
}

data "aws_iam_role" "grafana_cloudwatch" {
  name = "${var.team}-${var.project}-${var.env}-grafana-cloudwatch-role"
}

data "aws_iam_role" "cluster_autoscaler" {
  name = "${var.team}-${var.project}-${var.env}-cluster-autoscaler-role"
}

locals {
  # EKS 데이터 소스에서 필요한 정보 추출
  cluster_name     = data.aws_eks_cluster.cluster.name
  cluster_endpoint = data.aws_eks_cluster.cluster.endpoint
  cluster_ca       = data.aws_eks_cluster.cluster.certificate_authority[0].data
  vpc_id           = data.aws_eks_cluster.cluster.vpc_config[0].vpc_id
  oidc_issuer_url  = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer

  # OIDC 가공
  oidc_provider_host = replace(local.oidc_issuer_url, "https://", "")
  oidc_provider_arn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_provider_host}"

  common_tags = {
    Team      = var.team
    Project   = var.project
    ManagedBy = "terraform"
  }
}

# 2. IRSA Role 4개 (Prod 격리 이름 지정)

# 1. EBS CSI
resource "aws_iam_role" "ebs_csi" {
  name                 = "${var.team}-${var.project}-${var.env}-ebs-csi-role"
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
  tags = merge(local.common_tags, { Name = "${var.team}-${var.project}-${var.env}-ebs-csi-role" })
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# 2. ALB Controller
resource "aws_iam_policy" "alb_controller" {
  name   = "${var.team}-${var.project}-${var.env}-alb-controller-policy"
  policy = file("${path.module}/policies/alb-controller-policy.json")
  tags   = local.common_tags
}

resource "aws_iam_role" "alb_controller" {
  name                 = "${var.team}-${var.project}-${var.env}-alb-controller-role"
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
  tags = merge(local.common_tags, { Name = "${var.team}-${var.project}-${var.env}-alb-controller-role" })
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

# 3. ESO (Prod Parameter Store 전용)
resource "aws_iam_role" "eso" {
  name                 = "${var.team}-${var.project}-${var.env}-eso-role"
  permissions_boundary = var.permissions_boundary

  lifecycle {
    ignore_changes = [assume_role_policy]
  }

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
  tags = merge(local.common_tags, {
    Name = "${var.team}-${var.project}-${var.env}-eso-role"
  }
  )
}

resource "aws_iam_role_policy" "eso_ssm" {
  name = "${var.team}-${var.project}-${var.env}-eso-ssm"
  role = aws_iam_role.eso.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
      Resource = "arn:aws:ssm:ap-northeast-2:*:parameter/team3/matnani/prod/*"
    }]
  })

  lifecycle {
    ignore_changes = [policy]
  }
}
/*
# 4. ExternalDNS
resource "aws_iam_role" "external_dns" {
  name                 = "${var.team}-${var.project}-${var.env}-external-dns-role"
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
  tags = merge(local.common_tags, { Name = "${var.team}-${var.project}-${var.env}-external-dns-role" })
}

resource "aws_iam_role_policy" "external_dns_route53" {
  name = "${var.team}-${var.project}-${var.env}-external-dns-route53"
  role = aws_iam_role.external_dns.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["route53:ChangeResourceRecordSets"], Resource = "arn:aws:route53:::hostedzone/${var.route53_zone_id}" },
      { Effect = "Allow", Action = ["route53:ListHostedZones", "route53:ListResourceRecordSets"], Resource = "*" }
    ]
  })
}*/


# 3. modules/addons 호출
module "addons" {
  source = "../../../modules/addons"

  team                   = var.team
  project                = var.project
  env                    = var.env
  environment            = var.env
  cluster_name           = local.cluster_name
  cluster_endpoint       = local.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca
  vpc_id                 = local.vpc_id

  alb_controller_role_arn     = aws_iam_role.alb_controller.arn
  eso_role_arn                = aws_iam_role.eso.arn
  external_dns_role_arn       = ""
  enable_external_dns         = false
  grafana_admin_password      = data.aws_ssm_parameter.grafana_password.value
  grafana_cloudwatch_role_arn = data.aws_iam_role.grafana_cloudwatch.arn
  cluster_autoscaler_role_arn = data.aws_iam_role.cluster_autoscaler.arn
  slack_webhook_url           = data.aws_ssm_parameter.slack_webhook_url.value
}
