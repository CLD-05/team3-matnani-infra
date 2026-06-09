# modules/eks/outputs.tf
#
# Outputs:
#   - cluster_name     : platform-addons provider 초기화 + kubeconfig 설정 시 참조
#   - cluster_endpoint : platform-addons helm provider 초기화 시 참조
#   - cluster_ca       : platform-addons helm provider 초기화 시 참조
#   - node_sg_id       : database, elasticache 모듈 인바운드 규칙에서 참조
#                        RDS 3306, Redis 6379 인바운드 허용
#   - node_role_arn    : EBS CSI IRSA 설정 시 참조
#   - oidc_issuer_url  : platform-addons IRSA 신뢰 정책 Federated 값으로 참조

output "cluster_name" {
  description = "EKS 클러스터 이름 — kubeconfig 설정 및 platform-addons에서 참조"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS API 서버 엔드포인트 — platform-addons helm provider 초기화 시 참조"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_ca" {
  description = "EKS 클러스터 CA 인증서 — platform-addons helm provider 초기화 시 참조"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "node_sg_id" {
  description = "EKS 노드 SG ID — database, elasticache 모듈 인바운드 규칙에서 참조"
  value       = aws_security_group.node.id
}

output "node_role_arn" {
  description = "EKS 노드 IAM Role ARN"
  value       = aws_iam_role.node.arn
}

output "oidc_issuer_url" {
  description = "EKS OIDC Issuer URL — platform-addons IRSA 신뢰 정책에서 참조"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "IAM OIDC OpenID Connect Provider ARN"
  value       = aws_iam_openid_connect_provider.eks.arn
}