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
