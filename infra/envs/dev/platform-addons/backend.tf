# envs/dev/platform-addons/backend.tf

terraform {
  backend "s3" {
    bucket       = "tfstate-lionkdt5-team3"
    key          = "team3/dev/platform-addons/terraform.tfstate"
    region       = "ap-northeast-2"
    encrypt      = true
    use_lockfile = true
  }
}