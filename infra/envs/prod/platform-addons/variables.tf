# variables.tf

variable "team" {
  type    = string
  default = "team3"
}

variable "project" {
  type    = string
  default = "matnani"
}

variable "env" {
  type    = string
  default = "prod"
}

variable "cluster_name" {
  description = "EKS 클러스터 이름 (Prod)"
  type        = string
  default     = "team3-matnani-prod-eks"
}

variable "permissions_boundary_name" {
  description = "IAM Role 권한 경계 정책 이름"
  type        = string
  default     = "TeamRuntimeBoundary"
}

variable "route53_zone_id" {
  description = "ExternalDNS Route53 Hosted Zone ID"
  type        = string
}

variable "grafana_admin_password" {
  description = "SSM /matnani/prod/grafana-password 값"
  type        = string
  sensitive   = true
}