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

variable "rds_instance_id" {
  description = "RDS 인스턴스 식별자"
  type        = string
  default     = "team3-matnani-dev-mysql"
}

variable "redis_cluster_id" {
  description = "ElastiCache 클러스터 ID"
  type        = string
  default     = "team3-matnani-dev-redis-001"
}

variable "eks_cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
  default     = "team3-matnani-dev-eks"
}
