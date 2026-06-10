# envs/prod/infra/main.tf

module "network" {
  source = "../../../modules/network"

  env     = var.env
  team    = var.team
  project = var.project

  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_cidrs
  private_subnet_cidrs = var.private_cidrs
  db_subnet_cidrs      = var.isolated_cidrs

  # prod: AZ별 NAT GW (가용성 확보)
  single_nat_gateway = false
}

module "eks" {
  source               = "../../../modules/eks"
  permissions_boundary = var.permissions_boundary

  team    = var.team
  project = var.project

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  # prod: 퍼블릭 API 접근 차단
  endpoint_public_access = false

  node_instance_types = var.node_instance_type
  node_desired_size   = var.node_desired
  node_min_size       = var.node_min
  node_max_size       = var.node_max

  vpc_cni_version            = var.vpc_cni_version
  coredns_version            = var.coredns_version
  kube_proxy_version         = var.kube_proxy_version
  ebs_csi_version            = var.ebs_csi_version
  pod_identity_agent_version = var.pod_identity_agent_version

  team_member_user_arns = var.team_member_user_arns
}

# prod bastion — SSM 접속, SSH 22번 닫음
module "bastion" {
  source               = "../../../modules/bastion"
  permissions_boundary = var.permissions_boundary

  team    = var.team
  project = var.project

  vpc_id           = module.network.vpc_id
  public_subnet_id = module.network.public_subnet_ids[0]
  instance_type    = var.bastion_instance_type
}

# SSM에서 민감값 읽기 — prod 경로
data "aws_ssm_parameter" "db_username" {
  name = "/team3/matnani/prod/db-username"
}

data "aws_ssm_parameter" "db_password" {
  name            = "/team3/matnani/prod/db-password"
  with_decryption = true
}

module "database" {
  source = "../../../modules/database"

  env     = var.env
  team    = var.team
  project = var.project

  db_name     = var.db_name
  db_username = data.aws_ssm_parameter.db_username.value
  db_password = data.aws_ssm_parameter.db_password.value

  vpc_id         = module.network.vpc_id
  db_subnet_ids  = module.network.db_subnet_ids
  eks_node_sg_id = module.eks.node_sg_id
  # prod: bastion → RDS 디버깅 허용
  bastion_sg_id  = module.bastion.security_group_id

  instance_class          = var.db_instance_class
  allocated_storage       = var.allocated_storage
  max_allocated_storage   = var.max_allocated_storage
  multi_az                = var.multi_az
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot
  backup_retention_period = var.backup_retention_period

  create_read_replica    = var.create_read_replica
  replica_instance_class = var.replica_instance_class
}

module "elasticache" {
  source = "../../../modules/elasticache"

  env     = var.env
  team    = var.team
  project = var.project

  redis_version = var.redis_version
  node_type     = var.redis_node_type

  vpc_id         = module.network.vpc_id
  subnet_ids     = module.network.db_subnet_ids
  eks_node_sg_id = module.eks.node_sg_id

  # prod: 멀티 노드, 장애조치 활성
  num_cache_clusters         = var.redis_num_nodes
  automatic_failover_enabled = var.redis_num_nodes > 1

  at_rest_encryption_enabled = var.redis_at_rest_encryption
  transit_encryption_enabled = var.redis_transit_encryption

  snapshot_retention_limit = var.redis_snapshot_retention_limit
  apply_immediately        = var.redis_apply_immediately
}

module "ecr" {
  source = "../../../modules/ecr"

  team         = var.team
  project      = var.project
  repositories = ["api"]
}

module "cloudfront" {
  source = "../../../modules/cloudfront"

  team    = var.team
  project = var.project
  env     = var.env
}

module "github_oidc" {
  source = "../../../modules/github_oidc"

  team    = var.team
  project = var.project

  github_org           = var.github_org
  app_repo             = var.app_repo
  infra_repo           = var.infra_repo
  ecr_repository_arns  = values(module.ecr.repository_arns)
  permissions_boundary = var.permissions_boundary

  frontend_bucket_arn         = module.cloudfront.frontend_bucket_arn
  cloudfront_distribution_arn = module.cloudfront.distribution_arn
}

# SSM에서 민감값 읽기 — prod 경로
data "aws_ssm_parameter" "grafana_password" {
  name            = "/team3/matnani/prod/grafana-password"
  with_decryption = true
}

data "aws_ssm_parameter" "slack_workspace_id" {
  name            = "/team3/matnani/prod/slack-workspace-id"
  with_decryption = true
}

data "aws_ssm_parameter" "slack_channel_id" {
  name            = "/team3/matnani/prod/slack-channel-id"
  with_decryption = true
}

module "monitoring" {
  source = "../../../modules/monitoring"

  team        = var.team
  project     = var.project
  environment = var.env

  # prod: 30일 보존
  log_retention_days   = var.log_retention_days
  slack_workspace_id   = data.aws_ssm_parameter.slack_workspace_id.value
  slack_channel_id     = data.aws_ssm_parameter.slack_channel_id.value
  rds_identifier       = module.database.db_instance_id
  permissions_boundary = var.permissions_boundary
}