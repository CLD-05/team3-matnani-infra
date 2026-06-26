# infra/envs/dev/fis/variables.tf

variable "env" {
  description = "배포 환경"
  type        = string
  default     = "dev"
}

variable "team" {
  description = "팀 식별자"
  type        = string
  default     = "team3"
}

variable "project" {
  description = "프로젝트 식별자"
  type        = string
  default     = "matnani"
}
