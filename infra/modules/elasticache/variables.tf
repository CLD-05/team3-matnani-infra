variable "env" {
  description = "Environment name (dev/prod)"
  type        = string
}

variable "team" {
  description = "Team identifier"
  type        = string
  default     = "team3"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "matnani"
}

variable "redis_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.1"
}

variable "node_type" {
  description = "ElastiCache node instance type"
  type        = string
  default     = "cache.t3.micro"
}

variable "num_cache_clusters" {
  description = "Number of nodes in the replication group (1 = primary only, no replica)"
  type        = number
  default     = 2
}

variable "vpc_id" {
  description = "VPC ID for the Redis security group"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the ElastiCache subnet group (use DB/isolated subnets)"
  type        = list(string)
}

variable "eks_node_sg_id" {
  description = "EKS node security group ID — allowed to connect to Redis"
  type        = string
}

variable "automatic_failover_enabled" {
  description = "Enable automatic failover — requires num_cache_clusters >= 2"
  type        = bool
  default     = true
}

variable "at_rest_encryption_enabled" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "transit_encryption_enabled" {
  description = "Enable TLS in-transit encryption"
  type        = bool
  default     = false
}

variable "auth_token" {
  description = "Redis AUTH token — required when transit_encryption_enabled = true"
  type        = string
  sensitive   = true
  default     = null
}

variable "snapshot_retention_limit" {
  description = "Daily snapshot retention (days); 0 disables snapshots"
  type        = number
  default     = 1
}

variable "apply_immediately" {
  description = "Apply changes immediately — true for dev, false for prod"
  type        = bool
  default     = false
}
