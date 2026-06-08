# TF_VAR_db_username / TF_VAR_db_password 환경변수로 주입
# prod에서는 AWS Secrets Manager 또는 SSM Parameter Store 사용 권장

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
