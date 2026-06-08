# modules/ecr/variables.tf

variable "team" {
  description = "팀 식별자 (예: team3)"
  type        = string
}

variable "project" {
  description = "프로젝트명 (예: matnani)"
  type        = string
}

variable "repositories" {
  description = "생성할 ECR 레포지토리 이름 목록"
  type        = list(string)
  default     = ["api"]
}