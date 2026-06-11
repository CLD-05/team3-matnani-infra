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
  default     = true  # ReadReplica=true 로 설정
}

variable "replica_instance_class" {
  description = "Read Replica 인스턴스 타입"
  type        = string
  default     = "db.t3.large"
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
  description = "설정 변경 사항 즉시 반영 여부 (prod 환경은 정기 점검 시 반영 권장)"
  default     = false
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
  default = 3
}

variable "node_max" {
  type    = number
  default = 8
}

variable "node_desired" {
  type    = number
  default = 3
}

# EKS 클러스터 필수 애드온 버전 관리
variable "vpc_cni_version" {
  type    = string
  default = "v1.19.3-eksbuild.1"
}

variable "coredns_version" {
  type    = string
  default = "v1.11.4-eksbuild.2"
}

variable "kube_proxy_version" {
  type    = string
  default = "v1.32.3-eksbuild.2"
}

variable "ebs_csi_version" {
  type    = string
  default = "v1.41.0-eksbuild.1"
}

variable "pod_identity_agent_version" {
  type    = string
  default = "v1.3.4-eksbuild.1"
}

variable "endpoint_public_access" {
  description = "prod: false (퍼블릭 API 접근 차단)"
  type        = bool
  default     = false
}

variable "team_member_user_arns" {
  description = "EKS Access Entry 팀원 IAM 유저 ARN 맵"
  type        = map(string)
  default     = {}
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

variable "github_repo" {
  type        = string
  description = "GitHub 레포지토리명"
}

variable "app_repo" {
  type        = string
  description = "앱 소스 레포지토리명"
  default     = "team3-matnani-app"
}

variable "infra_repo" {
  type = string
}

# monitoring
variable "prometheus_storage_class" {
  type        = string
  description = "gp2"
}

variable "log_retention_days" {
  description = "CloudWatch 로그 보존 기간 (dev: 3 / prod: 30)"
  type        = number
  default     = 30
}

variable "prometheus_storage_size" {
  type        = string
  description = "10Gi"
}
