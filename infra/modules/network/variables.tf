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

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets — app/EKS nodes (one per AZ)"
  type        = list(string)
}

variable "db_subnet_cidrs" {
  description = "CIDR blocks for isolated DB subnets (one per AZ)"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Use a single shared NAT Gateway — saves cost in dev"
  type        = bool
  default     = false
}

variable "bastion_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH into the bastion host (port 22)"
  type        = list(string)
  default     = []
}
