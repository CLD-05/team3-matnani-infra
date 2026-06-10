# modules/bastion/variables.tf

variable "team" {
  description = "팀 식별자 (예: team3)"
  type        = string
}

variable "project" {
  description = "프로젝트명 (예: matnani)"
  type        = string
}

variable "env" {
  description = "배포 환경 (dev/prod)"
  type        = string
}

variable "vpc_id" {
  description = "network 모듈 output — Security Group 생성용"
  type        = string
}

variable "public_subnet_id" {
  description = "network 모듈 output — Bastion 배치할 퍼블릭 서브넷 ID"
  type        = string
}

variable "instance_type" {
  description = "Bastion EC2 인스턴스 타입"
  type        = string
  default     = "t3.micro"
}

variable "permissions_boundary" {
  description = "IAM Role 권한 경계 ARN — team3-* role 생성 시 필수"
  type        = string
  default     = "arn:aws:iam::495599735720:policy/TeamRuntimeBoundary"
}