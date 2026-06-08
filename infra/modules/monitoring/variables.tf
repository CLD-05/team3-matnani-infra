# modules/monitoring/variable.tf

variable "environment" {
  description = "배포 환경 (dev / prod)"
  type        = string
  default     = "dev"
}