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
  default     = "db.t3.large"
}

variable "create_read_replica" {
  description = "Read Replica 생성 여부"
  type        = bool
  default     = false
}

variable "replica_instance_class" {
  description = "Read Replica 인스턴스 타입 (create_read_replica = true 시 필수)"
  type        = string
  default     = null
}

# ──────────────── ElastiCache ────────────────
variable "redis_node_type" {
  description = "ElastiCache Redis 노드 타입"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_num_nodes" {
  description = "Redis replication group 노드 수 (1 = primary only)"
  type        = number
  default     = 1
}
