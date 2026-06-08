# ─────────────────────── Network ───────────────────────
module "network" {
  source = "../../../modules/network"

  env     = "dev"
  team    = "team3"
  project = "matnani"

  vpc_cidr = "10.3.0.0/16"

  azs = ["ap-northeast-2a", "ap-northeast-2c"]

  public_subnet_cidrs  = ["10.3.1.0/24", "10.3.2.0/24"]
  private_subnet_cidrs = ["10.3.11.0/24", "10.3.12.0/24"]
  db_subnet_cidrs      = ["10.3.21.0/24", "10.3.22.0/24"]

  # dev: 단일 NAT GW로 비용 절감 (prod은 AZ별 NAT GW 사용)
  single_nat_gateway = true

  # dev: 팀 작업 IP로 제한 권장, 임시로 전체 허용
  bastion_allowed_cidrs = ["0.0.0.0/0"]
}

# ─────────────────────── Database ──────────────────────
module "database" {
  source = "../../../modules/database"

  env     = "dev"
  team    = "team3"
  project = "matnani"

  db_name     = "matnani"
  db_username = var.db_username
  db_password = var.db_password

  db_subnet_ids          = module.network.db_subnet_ids
  vpc_security_group_ids = [module.network.sg_rds_id]

  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  max_allocated_storage   = 50
  multi_az                = false
  deletion_protection     = false
  skip_final_snapshot     = true
  backup_retention_period = 1
}

# ─────────────────────── ElastiCache ───────────────────
module "elasticache" {
  source = "../../../modules/elasticache"

  env     = "dev"
  team    = "team3"
  project = "matnani"

  redis_version = "7.1"
  node_type     = "cache.t3.micro"

  subnet_ids             = module.network.db_subnet_ids
  vpc_security_group_ids = [module.network.sg_redis_id]

  # dev: 단일 노드, 장애조치 비활성
  num_cache_clusters         = 1
  automatic_failover_enabled = false

  at_rest_encryption_enabled = true
  transit_encryption_enabled = false

  snapshot_retention_limit = 0
  apply_immediately        = true
}
