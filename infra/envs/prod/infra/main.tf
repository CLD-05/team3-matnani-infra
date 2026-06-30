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

  # prod: AZ별 NAT GW
  single_nat_gateway = false
  enable_nat         = var.node_desired > 0
}

module "eks" {
  source               = "../../../modules/eks"
  permissions_boundary = var.permissions_boundary

  env     = var.env
  team    = var.team
  project = var.project

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  network_ready      = module.network.public_internet_route_id

  # 기본값은 비공개이며, 초기 구축 시에만 tfvars로 명시적으로 활성화합니다.
  endpoint_public_access = var.endpoint_public_access

  node_instance_types = var.node_instance_type
  node_desired_size   = var.node_desired
  node_min_size       = var.node_min
  node_max_size       = var.node_max

  vpc_cni_version            = var.vpc_cni_version
  coredns_version            = var.coredns_version
  kube_proxy_version         = var.kube_proxy_version
  ebs_csi_version            = var.ebs_csi_version
  pod_identity_agent_version = var.pod_identity_agent_version
  # ebs_csi_role_arn = "arn:aws:iam::495599735720:role/team3-matnani-prod-ebs-csi-role"  # platform-addons 적용 후 주석 해제
  team_member_user_arns = var.team_member_user_arns
  gha_role_arn          = module.github_oidc.gha_prod_role_arn
}

# prod bastion — SSM 접속, SSH 22번 닫음
module "bastion" {
  source               = "../../../modules/bastion"
  permissions_boundary = var.permissions_boundary

  env     = var.env
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

  vpc_id            = module.network.vpc_id
  db_subnet_ids     = module.network.db_subnet_ids
  eks_node_sg_id    = module.eks.node_sg_id
  eks_cluster_sg_id = module.eks.cluster_sg_id
  # prod: bastion → RDS 디버깅 허용
  bastion_sg_id = module.bastion.security_group_id

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

  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.db_subnet_ids
  eks_node_sg_id    = module.eks.node_sg_id
  eks_cluster_sg_id = module.eks.cluster_sg_id
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

  env          = var.env
  team         = var.team
  project      = var.project
  repositories = ["api"]
}

module "cloudfront" {
  source       = "../../../modules/cloudfront"
  env          = var.env
  team         = var.team
  project      = var.project
  alb_dns_name = var.alb_dns_name
}

module "github_oidc" {
  source = "../../../modules/github_oidc"

  env                         = var.env
  team                        = var.team
  project                     = var.project
  github_org                  = var.github_org
  app_repo                    = var.app_repo
  infra_repo                  = var.infra_repo
  ecr_repository_arns         = values(module.ecr.repository_arns)
  permissions_boundary        = var.permissions_boundary
  frontend_bucket_arn         = module.cloudfront.frontend_bucket_arn
  cloudfront_distribution_arn = module.cloudfront.distribution_arn
  manage_infra_roles          = false
}

# Prod 모니터링 1단계:
# CloudWatch 알람 → SNS → Amazon Q Developer → Slack 파이프라인을 활성화합니다.
# AIOps와 ALB 알람, EKS 내부 리소스는 각 선행 리소스가 준비된 뒤 별도로 활성화합니다.

/* AIOps 활성화 시 주석을 해제하고 module.monitoring에 값을 전달합니다.
data "aws_ssm_parameter" "slack_webhook" {
  name            = "/team3/matnani/prod/monitoring/slack-webhook"
  with_decryption = true
}
*/

/* ALB Ingress 배포 후 ALB 알람을 활성화할 때 사용합니다.
data "aws_lb_target_group" "matnani" {
  name = var.alb_target_group_name
}
*/

module "monitoring" {
  source = "../../../modules/monitoring"

  team    = var.team
  project = var.project
  env     = var.env

  slack_workspace_id = var.slack_workspace_id
  slack_channel_id   = var.slack_channel_id
  chatbot_role_arn   = var.chatbot_role_arn

  enable_cluster_resources = false
  enable_aiops             = false
  enable_alb_alarms        = false
  enable_eks_alarms        = false
  log_retention_days       = var.log_retention_days

  eks_cluster_name = module.eks.cluster_name
  rds_instance_id  = module.database.db_instance_id
  alb_dns_name     = var.alb_dns_name
  alb_name         = var.alb_name
  nat_gateway_id   = module.network.nat_gateway_ids

  redis_cluster_id            = "${module.elasticache.redis_replication_group_id}-001"
  redis_connections_threshold = 80

  rds_cpu_threshold                 = var.rds_cpu_threshold
  rds_connections_threshold         = var.rds_connections_threshold
  rds_read_latency_threshold        = var.rds_read_latency_threshold
  rds_write_latency_threshold       = var.rds_write_latency_threshold
  rds_free_storage_threshold_bytes  = var.rds_free_storage_threshold_bytes
  eks_node_cpu_threshold            = var.eks_node_cpu_threshold
  eks_node_memory_threshold         = var.eks_node_memory_threshold
  alb_request_count_threshold       = var.alb_request_count_threshold
  alb_http_4xx_threshold            = var.alb_http_4xx_threshold
  alb_http_5xx_threshold            = var.alb_http_5xx_threshold
  nat_gw_connection_count_threshold = var.nat_gw_connection_count_threshold
  nat_gw_bytes_out_threshold        = var.nat_gw_bytes_out_threshold
}
