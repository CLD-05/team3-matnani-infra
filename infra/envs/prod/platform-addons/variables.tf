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
  description = "EKS 클러스터 이름"
  type        = string
  default     = "team3-matnani-eks"
}

variable "permissions_boundary" {
  description = "IAM Role 권한 경계"
  type        = string
  default     = "arn:aws:iam::495599735720:policy/TeamRuntimeBoundary"
}

variable "route53_zone_id" {
  description = "ExternalDNS Route53 Hosted Zone ID"
  type        = string
  default     = null
}

