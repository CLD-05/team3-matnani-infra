# infra/envs/dev/infra/variables.tf

# TF_VAR_db_username / TF_VAR_db_password 환경변수로 주입
# prod에서는 AWS Secrets Manager 또는 SSM Parameter Store 사용 권장

# 공통
variable "env" {
  type    = string
  default = "dev"
}

variable "team" {
  type    = string
  default = "team3"
}

variable "project" {
  type    = string
  default = "matnani"
}

variable "permissions_boundary" {
  description = "IAM Role 권한 경계 ARN — 미적용 시 생성 거부"
  type        = string
  default     = "arn:aws:iam::495599735720:policy/TeamRuntimeBoundary"
}


# DB
variable "db_name" {
  description = "RDS name"
  type        = string
  default     = "matnani"
}

variable "db_instance_class" {
  description = "RDS 인스턴스 타입"
  type        = string
  default     = "db.t4g.micro"
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
variable "allocated_storage" {
  type    = number
  default = 20
}

variable "max_allocated_storage" {
  type    = number
  default = 50
}

variable "backup_retention_period" {
  type    = number
  default = 1
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}



# Redis
variable "redis_node_type" {
  description = "ElastiCache Redis 노드 타입"
  type        = string
  default     = "cache.t4g.micro"
}

variable "redis_num_nodes" {
  description = "Redis replication group 노드 수 (1 = primary only)"
  type        = number
  default     = 1
}

variable "redis_version" {
  description = "ElastiCache Redis version"
  type        = string
  default     = "7.1"
}

variable "redis_at_rest_encryption" {
  type        = bool
  description = "저장 데이터 암호화(Encryption at Rest) 활성화 여부"
  default     = true
}

variable "redis_transit_encryption" {
  type        = bool
  description = "전송 중 데이터 암호화(Encryption in Transit) 활성화 여부"
  default     = false
}

variable "redis_snapshot_retention_limit" {
  type        = number
  description = "ElastiCache 자동 백업 스냅샷 보존 기간 (일)"
  default     = 0
}

variable "redis_apply_immediately" {
  type        = bool
  description = "설정 변경 사항 즉시 반영 여부 (prod 환경은 정기 점검 시 반영 권장)"
  default     = true
}



# VPC
variable "vpc_cidr" {
  type    = string
  default = "10.33.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_cidrs" {
  type    = list(string)
  default = ["10.33.1.0/24", "10.33.2.0/24"]
}

variable "private_cidrs" {
  type    = list(string)
  default = ["10.33.11.0/24", "10.33.12.0/24"]
}

variable "isolated_cidrs" {
  type    = list(string)
  default = ["10.33.21.0/24", "10.33.22.0/24"]
}


# EKS
variable "node_instance_type" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_min" {
  type    = number
  default = 2
}

variable "node_max" {
  type    = number
  default = 8
}

variable "node_desired" {
  type    = number
  default = 4
}

variable "team_member_user_arns" {
  description = "EKS Access Entry 팀원 IAM 유저 ARN 맵 — tfvars에서 주입"
  type        = map(string)
}

# EKS 클러스터 필수 애드온 버전 관리
variable "vpc_cni_version" {
  type    = string
  default = "v1.22.1-eksbuild.2"
}

variable "coredns_version" {
  type    = string
  default = "v1.14.3-eksbuild.2"
}

variable "kube_proxy_version" {
  type    = string
  default = "v1.35.3-eksbuild.11"
}

variable "ebs_csi_version" {
  type    = string
  default = "v1.61.1-eksbuild.1"
}

variable "pod_identity_agent_version" {
  type    = string
  default = "v1.3.10-eksbuild.3"
}


# Bastion
variable "bastion_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "github_org" {
  type        = string
  description = "GitHub 조직명 또는 사용자명 — tfvars에서 주입"
}

variable "app_repo" {
  type        = string
  description = "앱 소스 레포지토리명 — tfvars에서 주입"
}

variable "infra_repo" {
  type        = string
  description = "인프라 관리 레포지토리명 — tfvars에서 주입"
}

/*
# AWS Chatbot variables are enabled after the IAM restrictions are resolved.
variable "slack_workspace_id" {
  type        = string
  description = "팀 공용 슬랙 워크스페이스 ID"
}

variable "slack_channel_id" {
  type        = string
  description = "알림을 수신할 팀 공용 슬랙 채널 ID"
}

variable "chatbot_role_arn" {
  description = "관리자가 생성한 AWS Chatbot IAM Role ARN"
  type        = string
}
*/

variable "alb_dns_name" {
  type        = string
  description = "alb dns name"
}

variable "alb_name" {
  type        = string
  description = "alb dns name"
  default     = "team3-matnani-dev-alb"
}

variable "rds_cpu_threshold" {
  type    = number
  default = 70
}

variable "rds_connections_threshold" {
  type    = number
  default = 15
}

variable "rds_read_latency_threshold" {
  type    = number
  default = 0.15
}

variable "rds_write_latency_threshold" {
  type    = number
  default = 0.15
}

variable "rds_free_storage_threshold_bytes" {
  type    = number
  default = 5368709120
}

variable "eks_node_cpu_threshold" {
  type    = number
  default = 70
}

variable "eks_node_memory_threshold" {
  type    = number
  default = 70
}

variable "alb_request_count_threshold" {
  type    = number
  default = 15000
}

variable "alb_http_4xx_threshold" {
  type    = number
  default = 20
}

variable "alb_http_5xx_threshold" {
  type    = number
  default = 5
}

variable "nat_gw_connection_count_threshold" {
  type    = number
  default = 40000
}

variable "nat_gw_bytes_out_threshold" {
  type    = number
  default = 5368709120
}
