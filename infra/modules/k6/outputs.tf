# modules/k6/outputs.tf

output "instance_id" {
  description = "SSM 접속 시 --target 값 — aws ssm start-session --target {instance_id}"
  value       = aws_instance.k6.id
}

output "sg_id" {
  description = "k6 Security Group ID — EKS 노드 SG 인바운드 허용 시 참조"
  value       = aws_security_group.k6.id
}
