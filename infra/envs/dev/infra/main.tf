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
}

# ─────────────────────── Bastion ───────────────────────
module "bastion" {
  source = "../../../modules/bastion"

  team    = "team3"
  project = "matnani"

  vpc_id           = module.network.vpc_id
  public_subnet_id = module.network.public_subnet_ids[0]
  instance_type    = "t3.micro"
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

  vpc_id         = module.network.vpc_id
  db_subnet_ids  = module.network.db_subnet_ids
  eks_node_sg_id = module.network.sg_eks_node_id
  bastion_sg_id  = module.bastion.security_group_id

  instance_class          = var.db_instance_class
  allocated_storage       = 20
  max_allocated_storage   = 50
  multi_az                = false
  deletion_protection     = false
  skip_final_snapshot     = true
  backup_retention_period = 1

  create_read_replica    = var.create_read_replica
  replica_instance_class = var.replica_instance_class
}

# ─────────────────────── ElastiCache ───────────────────
module "elasticache" {
  source = "../../../modules/elasticache"

  env     = "dev"
  team    = "team3"
  project = "matnani"

  redis_version = "7.1"
  node_type     = var.redis_node_type

  vpc_id         = module.network.vpc_id
  subnet_ids     = module.network.db_subnet_ids
  eks_node_sg_id = module.network.sg_eks_node_id

  # dev: 단일 노드(redis_num_nodes=1), 장애조치 비활성
  num_cache_clusters         = var.redis_num_nodes
  automatic_failover_enabled = var.redis_num_nodes > 1

  at_rest_encryption_enabled = true
  transit_encryption_enabled = false

  snapshot_retention_limit = 0
  apply_immediately        = true
}
