output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (app/EKS)"
  value       = aws_subnet.private[*].id
}

output "db_subnet_ids" {
  description = "DB subnet IDs (isolated)"
  value       = aws_subnet.db[*].id
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = aws_nat_gateway.this[*].id
}

output "sg_alb_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "sg_eks_node_id" {
  description = "EKS Node Security Group ID"
  value       = aws_security_group.eks_node.id
}

output "sg_rds_id" {
  description = "RDS Security Group ID"
  value       = aws_security_group.rds.id
}

output "sg_redis_id" {
  description = "ElastiCache Redis Security Group ID"
  value       = aws_security_group.redis.id
}
