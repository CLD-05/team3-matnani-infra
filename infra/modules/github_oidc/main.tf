# modules/github_oidc/main.tf

# 생성 리소스:
#   - aws_iam_openid_connect_provider : GitHub Actions OIDC Provider 조회
#   - aws_iam_role (gha-ci-role)      : app repo CI용
#                                       ECR push + S3 sync + CloudFront invalidation
#   - aws_iam_role_policy (ecr)       : ECR push 권한 (ECR ARN 한정)
#   - aws_iam_role_policy (frontend)  : S3 sync + CloudFront invalidation 권한
#   - aws_iam_role (gha-dev-role)     : infra repo dev 자동 apply
#   - aws_iam_role (gha-prod-role)    : infra repo prod 수동 승인 후 apply


locals {
  name = "${var.team}-${var.project}-${var.env}"

  common_tags = {
    Team      = var.team
    Project   = var.project
    ManagedBy = "terraform"
  }
}

# GitHub OIDC Provider
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_caller_identity" "current" {}

# CI Role (app repo)
# 역할: Docker build → ECR push → S3 sync → CloudFront
resource "aws_iam_role" "gha_ci" {
  name                 = "${local.name}-gha-ci-role"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # app repo main 브랜치만 assume 가능
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.app_repo}:ref:refs/heads/main"
        }
      }
    }]
  })


  tags = merge(local.common_tags, {
    Name = "${local.name}-gha-ci-role"
  })
}

# ECR push 권한
resource "aws_iam_role_policy" "gha_ci_ecr" {
  name = "${local.name}-gha-ci-ecr"
  role = aws_iam_role.gha_ci.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # ECR 로그인 토큰 발급 — 계정 전체 허용 불가피
        Sid      = "ECRLogin"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        # 이미지 push — ECR ARN 한정
        Sid    = "ECRPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
        ]
        Resource = var.ecr_repository_arns
      }
    ]
  })
}

# S3 sync + CloudFront invalidation 권한 (프론트엔드 배포용)
resource "aws_iam_role_policy" "gha_ci_frontend" {
  name = "${local.name}-gha-ci-frontend"
  role = aws_iam_role.gha_ci.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # React 빌드 결과물 S3 업로드 — frontend 버킷 한정
        Sid    = "S3FrontendDeploy"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Resource = [
          var.frontend_bucket_arn,
          "${var.frontend_bucket_arn}/*",
        ]
      },
      {
        # CloudFront 캐시 무효화 — 배포 후 즉시 반영
        Sid      = "CloudFrontInvalidation"
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation"]
        Resource = var.cloudfront_distribution_arn
      }
    ]
  })
}

# dev Role (infra repo)
# 역할: dev 환경 terraform apply 자동 실행
resource "aws_iam_role" "gha_dev" {
  count = var.manage_infra_roles ? 1 : 0

  name                 = "${var.team}-${var.project}-dev-gha-role"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.infra_repo}:*"
        }
      }
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${var.team}-${var.project}-dev-gha-role"
  })

  lifecycle {
    prevent_destroy = true
  }
}

/*
주석 처리 상태로 terraform apply → gha-prod-role 생성됨
AWS 콘솔에서 team3-matnani-prod-gha-role에 AdministratorAccess 수동 attach
 */
/*resource "aws_iam_role_policy_attachment" "gha_dev" {
  role       = aws_iam_role.gha_dev[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}*/

# prod Role (infra repo)
# 역할: prod 환경 terraform apply — GitHub Environment 수동 승인 후에만 실행
resource "aws_iam_role" "gha_prod" {
  count = var.manage_infra_roles ? 1 : 0

  name                 = "${var.team}-${var.project}-prod-gha-role"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.infra_repo}:environment:prod"
        }
      }
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${var.team}-${var.project}-prod-gha-role"
  })

  lifecycle {
    prevent_destroy = true
  }
}

/*
주석 처리 상태로 terraform apply → gha-prod-role 생성됨
AWS 콘솔에서 team3-matnani-prod-gha-role에 AdministratorAccess 수동 attach
 */
/*resource "aws_iam_role_policy_attachment" "gha_prod" {
  role       = aws_iam_role.gha_prod[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}*/
