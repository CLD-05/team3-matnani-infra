# TF_VAR_db_username / TF_VAR_db_password 환경변수로 주입
# prod에서는 AWS Secrets Manager 또는 SSM Parameter Store 사용 권장

variable "db_username" {
  description = "RDS master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS 인스턴스 타입"
  type        = string
  default     = "db.t3.large" # 추후 db.m6i.large 변경 가능
}

variable "create_read_replica" {
  description = "Read Replica 생성 여부"
  type        = bool
  default     = false
}

variable "replica_instance_class" {
  description = "Read Replica 인스턴스 타입"
  type        = string
  default     = "db.t3.large"
}

# ──────────── ElastiCache ────────────
variable "redis_node_type" {
  description = "ElastiCache Redis 노드 타입"
  type        = string
  default     = "cache.t4g.small" # 가이드: cache.m7g.large
}

variable "redis_num_nodes" {
  description = "Redis replication group 노드 수 (primary + replica)"
  type        = number
  default     = 2
}
