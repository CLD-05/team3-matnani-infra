# modules/k6/outputs.tf

output "instance_id" {
  description = "SSM 접속 시 --target 값 — aws ssm start-session --target {instance_id}"
  value       = aws_instance.k6.id
}
