locals {
  name_prefix = "${var.team}-${var.project}-${var.env}"

  common_tags = {
    Team        = var.team
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group" "redis" {
  name        = "${local.name_prefix}-sg-redis"
  description = "ElastiCache Redis: inbound from EKS nodes"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.eks_node_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-sg-redis" })
}

resource "aws_elasticache_subnet_group" "this" {
  name        = "${local.name_prefix}-redis-subnet"
  description = "Redis subnet group for ${local.name_prefix}"
  subnet_ids  = var.subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redis-subnet"
  })
}

resource "aws_elasticache_parameter_group" "this" {
  name        = "${local.name_prefix}-redis7"
  family      = "redis7"
  description = "Redis 7 parameters for ${local.name_prefix}"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redis7-pg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${local.name_prefix}-redis"
  description          = "Redis 7 replication group for ${local.name_prefix}"

  engine               = "redis"
  engine_version       = var.redis_version
  node_type            = var.node_type
  num_cache_clusters   = var.num_cache_clusters
  parameter_group_name = aws_elasticache_parameter_group.this.name
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [aws_security_group.redis.id]

  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  auth_token                 = var.transit_encryption_enabled ? var.auth_token : null

  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.automatic_failover_enabled

  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = "04:00-05:00"
  maintenance_window       = "mon:05:00-mon:06:00"

  apply_immediately = var.apply_immediately

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redis"
  })
}
