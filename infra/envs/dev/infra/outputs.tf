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
