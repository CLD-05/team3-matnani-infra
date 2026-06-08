output "sg_rds_id" {
  description = "RDS Security Group ID"
  value       = aws_security_group.rds.id
}

output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.this.id
}

output "db_endpoint" {
  description = "RDS connection endpoint (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "db_host" {
  description = "RDS hostname"
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "RDS port"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "db_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.this.arn
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.this.name
}

output "replica_endpoint" {
  description = "Read Replica 엔드포인트 (create_read_replica = false면 null)"
  value       = var.create_read_replica ? aws_db_instance.replica[0].endpoint : null
}

output "replica_host" {
  description = "Read Replica 호스트명"
  value       = var.create_read_replica ? aws_db_instance.replica[0].address : null
}
