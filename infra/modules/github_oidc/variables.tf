# modules/github_oidc/variables.tf

variable "team" {
  description = "팀 식별자 (예: team3)"
  type        = string
}

variable "project" {
  description = "프로젝트명 (예: matnani)"
  type        = string
}

variable "permissions_boundary" {
  description = "IAM Role 권한 경계 ARN — team3-* role 생성 시 필수"
  type        = string
  default     = "arn:aws:iam::495599735720:policy/TeamRuntimeBoundary"
}

variable "github_org" {
  description = "GitHub 조직 또는 유저명"
  type        = string
}

variable "app_repo" {
  description = "app 레포지토리명"
  type        = string
}

variable "infra_repo" {
  description = "infra 레포지토리명"
  type        = string
}

variable "ecr_repository_arns" {
  description = "ECR push 권한을 줄 레포지토리 ARN 목록 — ecr 모듈 output 참조"
  type        = list(string)
}

variable "frontend_bucket_arn" {
  description = "React 빌드 결과물 업로드할 S3 버킷 ARN — cloudfront 모듈 output 참조"
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "CloudFront 캐시 무효화 대상 배포 ARN — cloudfront 모듈 output 참조"
  type        = string
}