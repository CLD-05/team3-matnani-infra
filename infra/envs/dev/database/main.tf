# network outputs 참조 — terraform apply 순서: network → database
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "team3-matnani-tfstate"
    key    = "team3/dev/network/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

module "database" {
  source = "../../../modules/database"

  env     = "dev"
  team    = "team3"
  project = "matnani"

  db_name     = "matnani"
  db_username = var.db_username
  db_password = var.db_password

  db_subnet_ids          = data.terraform_remote_state.network.outputs.db_subnet_ids
  vpc_security_group_ids = [data.terraform_remote_state.network.outputs.sg_rds_id]

  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  max_allocated_storage   = 50
  multi_az                = false
  deletion_protection     = false
  skip_final_snapshot     = true
  backup_retention_period = 1
}
