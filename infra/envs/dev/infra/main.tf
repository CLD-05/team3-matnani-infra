# envs/dev/infra/main.tf

module "network" {
  source = "../../../modules/network"

  env     = var.env
  team    = var.team
  project = var.project

  vpc_cidr = var.vpc_cidr
  azs = var.azs
  public_subnet_cidrs  = var.public_cidrs
  private_subnet_cidrs = var.private_cidrs
  db_subnet_cidrs      = var.isolated_cidrs

  # dev: 단일 NAT GW로 비용 절감 (prod은 AZ별 NAT GW 사용)
  single_nat_gateway = true
  enable_nat = var.node_desired > 0
}


module "eks" {
  source = "../../../modules/eks"
  permissions_boundary = var.permissions_boundary
  env     = var.env
  team    = var.team
  project = var.project

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  # dev: 퍼블릭 API 접근 허용
  endpoint_public_access = true

  node_instance_types = var.node_instance_type
  node_desired_size   = var.node_desired
  node_min_size       = var.node_min
  node_max_size       = var.node_max

  vpc_cni_version            = var.vpc_cni_version
  coredns_version            = var.coredns_version
  kube_proxy_version         = var.kube_proxy_version
  ebs_csi_version            = var.ebs_csi_version
  ebs_csi_role_arn           = "arn:aws:iam::495599735720:role/team3-matnani-dev-ebs-csi-role"
  pod_identity_agent_version = var.pod_identity_agent_version

  team_member_user_arns = var.team_member_user_arns
  gha_role_arn          = module.github_oidc.gha_dev_role_arn
  enable_gha_access     = true
}


module "bastion" {
  source = "../../../modules/bastion"
  permissions_boundary = var.permissions_boundary
  env     = var.env
  team    = var.team
  project = var.project

  vpc_id           = module.network.vpc_id
  public_subnet_id = module.network.public_subnet_ids[0]
  instance_type    = var.bastion_instance_type
}

data "aws_ssm_parameter" "db_username" {
  name = "/team3/matnani/dev/db-username"
}

data "aws_ssm_parameter" "db_password" {
  name            = "/team3/matnani/dev/db-password"
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
  eks_node_sg_id    = module.eks.node_sg_id
  eks_cluster_sg_id = module.eks.cluster_sg_id
  bastion_sg_id     = module.bastion.security_group_id

  instance_class          = var.db_instance_class
  allocated_storage       = var.allocated_storage
  max_allocated_storage   = var.max_allocated_storage
  multi_az                = var.multi_az
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot
  backup_retention_period = var.backup_retention_period

  create_read_replica    = var.create_read_replica
  replica_instance_class = var.replica_instance_class

  # dev: db.t4g.micro는 Performance Insights 미지원
  performance_insights_enabled = false
}

module "elasticache" {
  source = "../../../modules/elasticache"

  env     = var.env
  team    = var.team
  project = var.project

  redis_version = var.redis_version
  node_type     = var.redis_node_type

  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.db_subnet_ids
  eks_node_sg_id    = module.eks.node_sg_id
  eks_cluster_sg_id = module.eks.cluster_sg_id

  # dev: 단일 노드(redis_num_nodes=1), 장애조치 비활성
  num_cache_clusters         = var.redis_num_nodes
  automatic_failover_enabled = var.redis_num_nodes > 1

  at_rest_encryption_enabled = var.redis_at_rest_encryption
  transit_encryption_enabled = var.redis_transit_encryption

  snapshot_retention_limit = var.redis_snapshot_retention_limit
  apply_immediately        = var.redis_apply_immediately
}


module "ecr" {
  source = "../../../modules/ecr"

  env     = var.env
  team    = var.team
  project = var.project
  repositories = ["api"]
}

module "cloudfront" {
  source  = "../../../modules/cloudfront"
  env     = var.env
  team    = var.team
  project = var.project
}


module "github_oidc" {
  source = "../../../modules/github_oidc"

  env     = var.env
  team    = var.team
  project = var.project
  github_org  = var.github_org
  infra_repo           = var.infra_repo
  ecr_repository_arns  = values(module.ecr.repository_arns)
  permissions_boundary = var.permissions_boundary
  frontend_bucket_arn         = module.cloudfront.frontend_bucket_arn
  cloudfront_distribution_arn = module.cloudfront.distribution_arn
  app_repo                  = var.app_repo
}


# TODO: EKS 클러스터 생성 후 활성화 (kubernetes provider 필요)
# data "aws_ssm_parameter" "grafana_password" {
#   name            = "/team3/matnani/dev/grafana-password"
#   with_decryption = true
# }

# data "aws_ssm_parameter" "slack_webhook" {
#   name            = "/team3/matnani/dev/monitoring/slack-webhook"
#   with_decryption = true
# }

# module "monitoring" {
#   source = "../../../modules/monitoring"
#
#   team    = var.team
#   project = var.project
#   env     = var.env
#
#   slack_workspace_id = var.slack_workspace_id
#   slack_channel_id   = var.slack_channel_id
#
#   prometheus_storage_class = var.prometheus_storage_class
#   prometheus_storage_size  = var.prometheus_storage_size
#   eks_cluster_name       = module.eks.cluster_name
#   rds_instance_id        = module.database.db_instance_id
#   alb_name               = ""
#   nat_gateway_id         = module.network.nat_gateway_ids[0]
#   slack_webhook_url      = data.aws_ssm_parameter.slack_webhook.value
#   grafana_admin_password = data.aws_ssm_parameter.grafana_password.value
#   permissions_boundary   = var.permissions_boundary
# }
