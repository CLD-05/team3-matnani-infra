# modules/monitoring/variables.tf

variable "team" {
  description = "팀명 (예: team3)"
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
variable "rds_instance_id" {
  description = "감시할 RDS 인스턴스 ID"
  type        = string
  default     = ""
}

variable "eks_cluster_name" {
  description = "감시할 EKS 클러스터 이름"
  type        = string
  default     = ""
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

variable "prometheus_storage_class" {
  description = "프로메테우스 EBS 스토리지 클래스 (gp2, gp3 등)"
  type        = string
  default     = "gp2"
}

variable "prometheus_storage_size" {
  description = "프로메테우스 스토리지 용량 크기"
  type        = string
  default     = "10Gi"
}

variable "slack_webhook_url" {
  description = "SSM Parameter Store에서 읽어온 슬랙 웹훅 URL"
  type        = string
  default     = ""
}

variable "grafana_admin_password" {
  description = "SSM Parameter Store에서 읽어온 그라파나 관리자 패스워드"
  type        = string
  sensitive   = true
}

variable "permissions_boundary" {
  description = "IAM Role 생성에 필요한 Permissions Boundary ARN"
  type        = string
  default     = null
}