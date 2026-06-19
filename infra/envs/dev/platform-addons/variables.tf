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
  default = "dev"
}

variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
  default     = "team3-matnani-dev-eks"
}

variable "permissions_boundary" {
  type    = string
  default = "arn:aws:iam::495599735720:policy/TeamRuntimeBoundary"
}

variable "github_org" {
  type    = string
  default = "CLD-05"
}

variable "app_repo" {
  type    = string
  default = "team3-matnani-app"
}

variable "infra_repo" {
  type    = string
  default = "team3-matnani-infra"
}

variable "team_member_user_arns" {
  type    = map(string)
  default = {}
}

# variable "route53_zone_id" {
#   description = "ExternalDNS Route53 Hosted Zone ID"
#   type        = string
# }

# variable "grafana_admin_password" {
#   description = "SSM /matnani/dev/grafana-password 값"
#   type        = string
#   sensitive   = true
# }