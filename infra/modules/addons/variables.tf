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

variable "vpc_id" {
    description = "ALB Controller가 ALB를 생성할 VPC ID"
    type        = string
}

variable "team" {
    type    = string
    default = "team3"
}

variable "project" {
    type    = string
    default = "matnani"
}
variable "eso_role_arn" {
    description = "ESO가 SSM에 접근하기 위한 IAM Role ARN"
    type        = string
    default     = null
}
variable "env" {
    description = "배포 환경 (dev/prod)"
    type    = string
}
variable "cloudwatch_log_group_name" {
    description = "CloudWatch Log Group name for Fluent Bit"
    type        = string
}