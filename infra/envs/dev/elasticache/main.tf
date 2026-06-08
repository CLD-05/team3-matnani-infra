# network outputs 참조 — terraform apply 순서: network → elasticache
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "team3-matnani-tfstate"
    key    = "team3/dev/network/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

module "elasticache" {
  source = "../../../modules/elasticache"

  env     = "dev"
  team    = "team3"
  project = "matnani"

  redis_version = "7.1"
  node_type     = "cache.t3.micro"

  subnet_ids             = data.terraform_remote_state.network.outputs.db_subnet_ids
  vpc_security_group_ids = [data.terraform_remote_state.network.outputs.sg_redis_id]

  # dev: 단일 노드, 장애조치 비활성
  num_cache_clusters         = 1
  automatic_failover_enabled = false

  at_rest_encryption_enabled = true
  transit_encryption_enabled = false

  snapshot_retention_limit = 0
  apply_immediately        = true
}
