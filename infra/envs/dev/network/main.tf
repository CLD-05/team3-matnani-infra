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
