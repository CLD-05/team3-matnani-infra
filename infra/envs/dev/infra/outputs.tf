# platform-addons에서 terraform_remote_state로 참조하는 outputs

output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "cluster_name" {
  description = "EKS 클러스터 이름"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API 서버 엔드포인트"
  value       = module.eks.cluster_endpoint
}

output "cluster_ca" {
  description = "EKS 클러스터 CA 인증서"
  value       = module.eks.cluster_ca
}

output "oidc_issuer_url" {
  description = "EKS OIDC Issuer URL"
  value       = module.eks.oidc_issuer_url
}

output "db_endpoint" {
  description = "RDS 엔드포인트"
  value       = module.database.db_endpoint
}

output "redis_endpoint" {
  description = "Redis primary 엔드포인트"
  value       = module.elasticache.redis_primary_endpoint
}

output "ecr_repository_urls" {
  description = "GitHub Actions CI에서 이미지 push 시 참조"
  value       = module.ecr.repository_urls
}

output "ecr_repository_arns" {
  description = "github_oidc 모듈 gha-ci-role 정책 Resource 지정 시 참조"
  value       = module.ecr.repository_arns
}


# GitHub OIDC
output "gha_ci_role_arn" {
  description = "GitHub Actions CI workflow role-to-assume 값"
  value       = module.github_oidc.gha_ci_role_arn
}

output "gha_dev_role_arn" {
  description = "GitHub Actions dev infra workflow role-to-assume 값"
  value       = module.github_oidc.gha_dev_role_arn
}

output "gha_prod_role_arn" {
  description = "GitHub Actions prod infra workflow role-to-assume 값"
  value       = module.github_oidc.gha_prod_role_arn
}


# CloudFront
output "cloudfront_domain_name" {
  description = "프론트엔드 접속 URL (prod만 생성)"
  value       = module.cloudfront.cloudfront_domain_name
}