variable "cluster_name" {
    description = "EKS 클러스터 식별자 (team3-matnani-eks)"
    type = string
}
variable "cluster_endpoint" {
    description = "Kubernetes API 서버 엔드포인트 엔드포인트 URL"
    type = string
}
variable "cluster_ca_certificate" {
    description = "Kubernetes 클러스터 인증기관(CA) 인증서 데이터"
    type = string
}
variable "environment" {
    description = "배포 타겟 운영 환경 (dev / prod)"
    type = string
    default = "dev"
}
variable "alb_controller_role_arn" {
    description = "AWS Load Balancer Controller 가 사용할 IAM IRSA Role ARN"
    type = string
}

variable "external_dns_role_arn" {
    description = "ExternalDNS IRSA Role ARN"
    type        = string
}

variable "grafana_admin_password" {
    description = "Grafana 관리자 비밀번호 — SSM에서 주입"
    type        = string
    sensitive   = true
}