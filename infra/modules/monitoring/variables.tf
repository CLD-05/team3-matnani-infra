# modules/monitoring/variables.tf

variable "environment" {
  description = "배포 환경 (dev / prod)"
  type        = string
  default     = "dev"
}

# [추가] Slack 연동을 위한 변수
variable "slack_workspace_id" {
  description = "Slack 워크스페이스 ID"
  type        = string
}

variable "slack_channel_id" {
  description = "알림을 받을 Slack 채널 ID"
  type        = string
}