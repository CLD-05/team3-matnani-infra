variable "team" {
  type = string
}

variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "slack_workspace_id" {
  description = "Slack workspace ID for AWS Chatbot."
  type        = string
}

variable "slack_channel_id" {
  description = "Slack channel ID for AWS Chatbot."
  type        = string
}

variable "rds_instance_id" {
  description = "RDS instance ID monitored by CloudWatch alarm."
  type        = string
  default     = ""
}

variable "eks_cluster_name" {
  description = "EKS cluster name."
  type        = string
  default     = ""
}

variable "prometheus_release_name" {
  description = "Existing kube-prometheus-stack Helm release name used by ServiceMonitor labels."
  type        = string
  default     = "team3-matnani-kube-prometheus-stack"
}

variable "alb_name" {
  description = "ALB name for future CloudWatch alarms."
  type        = string
  default     = null
}

variable "nat_gateway_id" {
  description = "NAT Gateway IDs for future CloudWatch alarms."
  type        = list(string)
  default     = []
}

variable "permissions_boundary" {
  description = "IAM permissions boundary ARN."
  type        = string
  default     = null
}

/*
# AWS Chatbot 권한 해결 후 사용할 변수
variable "enable_chatbot" {
  description = "Whether to create AWS Chatbot IAM and Slack channel resources."
  type        = bool
  default     = false
}

# 기존 kube-prometheus-stack에서 Slack Webhook과 Grafana 비밀번호를
# 직접 주입해야 할 경우 다시 활성화한다.
variable "slack_webhook_url" {
  description = "Slack Webhook URL loaded from SSM Parameter Store."
  type        = string
  default     = ""
}

variable "grafana_admin_password" {
  description = "Grafana admin password loaded from SSM Parameter Store."
  type        = string
  sensitive   = true
}
*/
