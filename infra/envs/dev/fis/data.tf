# infra/envs/dev/fis/data.tf

locals {
  prefix = "${var.team}-${var.project}-${var.env}"
}

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "tfstate-lionkdt5-team3"
    key    = "team3/dev/infra/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "aws_eks_node_group" "main" {
  cluster_name    = data.terraform_remote_state.infra.outputs.cluster_name
  node_group_name = "${data.terraform_remote_state.infra.outputs.cluster_name}-ng"
}

data "aws_db_instance" "main" {
  db_instance_identifier = "${local.prefix}-mysql"
}

data "aws_elasticache_replication_group" "main" {
  replication_group_id = "${local.prefix}-redis"
}
