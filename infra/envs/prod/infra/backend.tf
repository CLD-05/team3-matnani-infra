# envs/prod/infra/backend.tf

terraform {
  backend "s3" {
    bucket       = "tfstate-lionkdt5-team3"
    key          = "team3/prod/infra/terraform.tfstate"
    region       = "ap-northeast-2"
    encrypt      = true
    use_lockfile = true
  }
}