# ─────────────────────── Network ───────────────────────
module "network" {
  source = "../../../modules/network"

  env     = "prod"
  team    = "team3"
  project = "matnani"

  vpc_cidr = "10.3.0.0/16"

  azs = ["ap-northeast-2a", "ap-northeast-2c"]

  public_subnet_cidrs  = ["10.3.1.0/24", "10.3.2.0/24"]
  private_subnet_cidrs = ["10.3.11.0/24", "10.3.12.0/24"]
  db_subnet_cidrs      = ["10.3.21.0/24", "10.3.22.0/24"]

  # prod: AZ별 NAT GW (가용성 확보)
  single_nat_gateway = false
}

# ─────────────────────── Database ──────────────────────
module "database" {
  source = "../../../modules/database"

  env     = "prod"
  team    = "team3"
  project = "matnani"

  db_name     = "matnani"
  db_username = var.db_username
  db_password = var.db_password

  vpc_id         = module.network.vpc_id
  db_subnet_ids  = module.network.db_subnet_ids
  eks_node_sg_id = module.network.sg_eks_node_id
  bastion_sg_id  = ""

  instance_class          = var.db_instance_class
  allocated_storage       = 100
  max_allocated_storage   = 500
  multi_az                = true
  deletion_protection     = true
  skip_final_snapshot     = false
  backup_retention_period = 7

  create_read_replica    = var.create_read_replica
  replica_instance_class = var.replica_instance_class
}

# ─────────────────────── ElastiCache ───────────────────
module "elasticache" {
  source = "../../../modules/elasticache"

  env     = "prod"
  team    = "team3"
  project = "matnani"

  redis_version = "7.1"
  node_type     = var.redis_node_type

  vpc_id         = module.network.vpc_id
  subnet_ids     = module.network.db_subnet_ids
  eks_node_sg_id = module.network.sg_eks_node_id

  # prod: 멀티 노드, 장애조치 활성
  num_cache_clusters         = var.redis_num_nodes
  automatic_failover_enabled = true

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  snapshot_retention_limit = 7
  apply_immediately        = false
}
