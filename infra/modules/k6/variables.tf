# modules/k6/variables.tf

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
  description = "network 모듈 output — k6 EC2 배치할 퍼블릭 서브넷 ID"
  type        = string
}

variable "instance_type" {
  description = "k6 EC2 인스턴스 타입 (200 VU 기준 t3.medium 권장)"
  type        = string
  default     = "t3.medium"
}
