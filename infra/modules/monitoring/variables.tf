# modules/monitoring/variables.tf

variable "environment" {
  description = "배포 환경 (dev / prod)"
  type        = string
  default     = "dev"
}

# Slack 연동을 위한 변수
variable "slack_workspace_id" {
  description = "Slack 워크스페이스 ID"
  type        = string
}

variable "slack_channel_id" {
  description = "알림을 받을 Slack 채널 ID"
  type        = string
}

# 통합 관제를 위한 리소스 식별자 변수
variable "rds_identifier" {
  description = "감시할 RDS의 DB 인스턴스 ID"
  type        = string
  default     = null
}

variable "alb_name" {
  description = "감시할 ALB의 이름 (CloudWatch 지표용)"
  type        = string
  default     = null
}

variable "nat_gateway_id" {
  description = "감시할 NAT Gateway의 ID"
  type        = string
  default     = null
}