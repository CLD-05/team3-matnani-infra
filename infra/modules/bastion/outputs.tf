# modules/bastion/outputs.tf
#
# Outputs:
#   - instance_id       : SSM 접속 시 --target 값으로 사용
#                         aws ssm start-session --target {instance_id}
#   - bastion_role_arn  : 필요 시 EKS Access Entry 등록 시 참조
#   - security_group_id : database, elasticache 모듈 인바운드 규칙에서
#                         Bastion → RDS 3306 허용 시 참조

output "instance_id" {
  description = "SSM 접속 시 --target 값"
  value       = aws_instance.bastion.id
}

output "bastion_role_arn" {
  description = "Bastion IAM Role ARN"
  value       = aws_iam_role.bastion.arn
}

output "security_group_id" {
  description = "RDS SG 인바운드에서 Bastion → 3306 허용 시 참조"
  value       = aws_security_group.bastion.id
}