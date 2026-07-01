variable "team" {
  description = "팀 식별자 (예: team3)"
  type        = string
}

variable "project" {
  description = "프로젝트명 (예: matnani)"
  type        = string
}

variable "env" {
  description = "배포 환경 (dev / prod)"
  type        = string
}

variable "alb_dns_name" {
  description = "alb_dns_name"
  type        = string
}

variable "domain_name" {
  description = "커스텀 도메인 (예: matnani.store). 비워두면 CloudFront 기본 도메인 사용"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "CloudFront용 ACM 인증서 ARN (us-east-1 리전). domain_name 설정 시 필수"
  type        = string
  default     = ""
}
