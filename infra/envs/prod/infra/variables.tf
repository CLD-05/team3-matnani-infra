# infra/envs/prod/infra/variables.tf
# TF_VAR_db_username / TF_VAR_db_password 환경변수로 주입
# prod에서는 AWS Secrets Manager 또는 SSM Parameter Store 사용 권장

# 공통
variable "env" {
  type        = string
  description = "인프라 배포 환경"
  default     = "prod"
}

variable "team" {
  type        = string
  default     = "team3"
}

variable "project" {
  type        = string
  default     = "matnani"
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
  default     = "db.m6i.large"
}

variable "create_read_replica" {
  description = "Read Replica 생성 여부"
  type        = bool
  default     = true
}

variable "replica_instance_class" {
  description = "Read Replica 인스턴스 타입"
  type        = string
  default     = "db.m6i.large"
}

variable "allocated_storage" {
  type        = number
  default     = 100
}

variable "max_allocated_storage" {
  type        = number
  default     = 500
}

variable "backup_retention_period" {
  type        = number
  default     = 7
}

variable "multi_az" {
  type    = bool
  default = true
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "skip_final_snapshot" {
  type    = bool
  default = false
}


# Redis
variable "redis_node_type" {
  description = "ElastiCache Redis 노드 타입"
  type        = string
  default     = "cache.m7g.large"
}

variable "redis_num_nodes" {
  description = "Redis replication group 노드 수 (primary + replica)"
  type        = number
  default     = 2
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
  default     = true
}

variable "redis_apply_immediately" {
  type        = bool
  description = "설정 변경 사항 즉시 반영 여부"
  default     = true
}

variable "redis_automatic_failover_enabled" {
  type        = bool
  default     = true
}

variable "redis_snapshot_retention_limit" {
  type        = number
  description = "ElastiCache 자동 백업 스냅샷 보존 기간 (일)"
  default     = 7
}



# VPC
variable "vpc_cidr" {
  type    = string
  default = "10.3.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_cidrs" {
  type    = list(string)
  default = ["10.3.1.0/24", "10.3.2.0/24"]
}

variable "private_cidrs" {
  type    = list(string)
  default = ["10.3.11.0/24", "10.3.12.0/24"]
}

variable "isolated_cidrs" {
  type    = list(string)
  default = ["10.3.21.0/24", "10.3.22.0/24"]
}


# EKS
variable "node_instance_type" {
  type    = list(string)
  default = ["m6i.large"]
}

variable "node_min" {
  type    = number
  default = 4
}

variable "node_max" {
  type    = number
  default = 8
}

variable "node_desired" {
  type    = number
  default = 4
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

variable "endpoint_public_access" {
  description = "초기 구축 시 true, 노드 합류 확인 후 false로 변경"
  type        = bool
  default     = true
}

variable "team_member_user_arns" {
  description = "EKS Access Entry 팀원 IAM 유저 ARN 맵"
  type        = map(string)
}

# Bastion
variable "bastion_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "github_org" {
  type        = string
  description = "GitHub 조직명 또는 사용자명"
}

variable "app_repo" {
  type        = string
  description = "앱 소스 레포지토리명"
  default     = "team3-matnani-app"
}

variable "infra_repo" {
  type = string
  description = "인프라 관리 레포지토리명"
}

variable "log_retention_days" {
  description = "CloudWatch 로그 보존 기간 (dev: 3 / prod: 30)"
  type        = number
  default     = 30
}

variable "slack_workspace_id" {
  type        = string
  description = "팀 공용 슬랙 워크스페이스 ID"
}

variable "slack_channel_id" {
  type        = string
  description = "알림을 수신할 팀 공용 슬랙 채널 ID"
}

variable "chatbot_role_arn" {
  description = "Amazon Q Developer가 사용할 기존 IAM Role ARN"
  type        = string
}

variable "alb_dns_name" {
  type        = string
  description = "ALB DNS name"
}

variable "alb_name" {
  type        = string
  description = "ALB dns name"
  default     = "team3-matnani-prod-alb"
}

# ALB 배포 후 자동 생성되는 target group 이름 (kubectl get ingress 또는 콘솔에서 확인)
variable "alb_target_group_name" {
  type        = string
  description = "ALB Target Group 이름 — Ingress 배포 후 확인하여 입력"
  default     = ""
}

# ElastiCache 배포 후 확인: aws elasticache describe-replication-groups
variable "redis_cluster_id" {
  type        = string
  description = "ElastiCache 클러스터 ID — elasticache apply 후 확인하여 입력"
  default     = ""
}

# ---- 모니터링 임계값 (prod 기준) ----
variable "rds_cpu_threshold" {
  type    = number
  default = 70
}

variable "rds_connections_threshold" {
  type    = number
  default = 80
}

variable "rds_read_latency_threshold" {
  type    = number
  default = 0.1 # 100ms
}

variable "rds_write_latency_threshold" {
  type    = number
  default = 0.12 # 120ms
}

variable "rds_free_storage_threshold_bytes" {
  type    = number
  default = 32212254720 # 30GB
}

variable "eks_node_cpu_threshold" {
  type    = number
  default = 70
}

variable "eks_node_memory_threshold" {
  type    = number
  default = 80
}

variable "alb_request_count_threshold" {
  type    = number
  default = 70000
}

variable "alb_http_4xx_threshold" {
  type    = number
  default = 50
}

variable "alb_http_5xx_threshold" {
  type    = number
  default = 10
}

variable "nat_gw_connection_count_threshold" {
  type    = number
  default = 50000
}

variable "nat_gw_bytes_out_threshold" {
  type    = number
  default = 10737418240 # 10GB
}
