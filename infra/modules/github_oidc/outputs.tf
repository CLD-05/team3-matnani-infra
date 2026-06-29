# modules/github_oidc/outputs.tf
#
# Outputs:
#   - oidc_provider_arn  : eks 모듈 IRSA 신뢰 정책에서 Federated 값으로 참조
#   - gha_ci_role_arn    : GitHub Actions CI workflow role-to-assume 값
#   - gha_dev_role_arn   : GitHub Actions dev infra workflow role-to-assume 값
#   - gha_prod_role_arn  : GitHub Actions prod infra workflow role-to-assume 값

output "oidc_provider_arn" {
  description = "GitHub OIDC Provider ARN — eks 모듈 IRSA 신뢰 정책에서 참조"
  value       = data.aws_iam_openid_connect_provider.github.arn
}

output "oidc_provider_url" {
  description = "GitHub OIDC Provider URL — IRSA 신뢰 정책 Condition 작성 시 참조"
  value       = data.aws_iam_openid_connect_provider.github.url
}

output "gha_ci_role_arn" {
  description = "GitHub Actions CI Role ARN — app repo workflow에서 참조"
  value       = aws_iam_role.gha_ci.arn
}

output "gha_dev_role_arn" {
  description = "GitHub Actions dev infra Role ARN — dev workflow에서 참조"
  value       = var.manage_infra_roles ? aws_iam_role.gha_dev[0].arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.team}-${var.project}-dev-gha-role"
}

output "gha_prod_role_arn" {
  description = "GitHub Actions prod infra Role ARN — prod workflow에서 참조"
  value       = var.manage_infra_roles ? aws_iam_role.gha_prod[0].arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.team}-${var.project}-prod-gha-role"
}
