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

/*
# AWS Chatbot variables are enabled after the IAM restrictions are resolved.
variable "slack_workspace_id" {
  description = "Slack 워크스페이스 ID"
  type        = string
}

variable "slack_channel_id" {
  description = "알림을 받을 Slack 채널 ID"
  type        = string
}

variable "chatbot_role_arn" {
  description = "ARN of an existing IAM role trusted by chatbot.amazonaws.com"
  type        = string
}
*/

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

variable "alb_dns_name" {
  description = "감시할 ALB의 이름 (CloudWatch 지표용)"
  type        = string
}

variable "alb_name" {
  description = "감시할 ALB의 이름 (CloudWatch 지표용)"
  type        = string
  default     = "team3-matnani-dev-alb"
}

variable "nat_gateway_id" {
  description = "감시할 NAT Gateway의 ID"
  type        = list(string)
  default     = []
}

/*
# 기존 infra monitoring Helm 릴리스에서 사용하던 변수입니다.
# 현재 kube-prometheus-stack은 platform-addons에서 관리하므로 비활성화합니다.
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
*/

variable "target_group_name" {
  description = "Target Group Name"
  type        = string
}

variable "cloudwatch_log_group_name" {
  description = "cloudwatch log group name"
  type        = string
}

# ---- RDS ----
variable "rds_cpu_threshold" {
  type    = number
  default = 75
}

variable "rds_connections_threshold" {
  type    = number
  default = 80
}

variable "rds_read_latency_threshold" {
  type    = number
  default = 0.1 # 100ms -> CloudWatch 단위는 초(second)
}

variable "rds_write_latency_threshold" {
  type    = number
  default = 0.12 # 120ms
}

variable "rds_free_storage_threshold_bytes" {
  type    = number
  default = 32212254720 # 30GB
}

# ---- EKS ----
variable "eks_node_cpu_threshold" {
  type    = number
  default = 70
}

variable "eks_node_memory_threshold" {
  type    = number
  default = 65
}

# ---- ALB ----
variable "alb_request_count_threshold" {
  type    = number
  default = 70000
}

variable "alb_http_4xx_threshold" {
  type    = number
  default = 50
}

variable "alb_http_5xx_threshold" {
  type    = number
  default = 10
}

# ---- NAT Gateway ----
variable "nat_gw_connection_count_threshold" {
  type    = number
  default = 50000
}

variable "nat_gw_bytes_out_threshold" {
  type    = number
  default = 10737418240 # 10GB
}
