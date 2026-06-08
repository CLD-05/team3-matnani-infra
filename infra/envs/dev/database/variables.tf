# 민감 값은 TF_VAR_db_username / TF_VAR_db_password 환경변수 또는
# terraform.tfvars (gitignore 처리)로 주입
# prod에서는 AWS SSM Parameter Store 또는 Secrets Manager 참조 권장

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
