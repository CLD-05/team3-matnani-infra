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

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "matnani"
}

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

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "allocated_storage" {
  description = "Initial allocated storage (GB)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Upper limit for storage autoscaling (GB)"
  type        = number
  default     = 100
}

variable "vpc_id" {
  description = "VPC ID for the RDS security group"
  type        = string
}

variable "db_subnet_ids" {
  description = "DB subnet IDs for the subnet group"
  type        = list(string)
}

variable "eks_node_sg_id" {
  description = "EKS node security group ID — allowed to connect to RDS"
  type        = string
}

variable "bastion_sg_id" {
  description = "Bastion security group ID — allowed to connect to RDS"
  type        = string
}

variable "multi_az" {
  description = "Enable Multi-AZ standby replica"
  type        = bool
  default     = false
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

variable "deletion_protection" {
  description = "Prevent accidental deletion via Terraform"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy (set true only in dev)"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Automated backup retention (days)"
  type        = number
  default     = 7
}
