terraform {
  required_version = ">= 1.14.0, < 1.15.0"

  backend "s3" {
    bucket = "team3-matnani-tfstate"
    key    = "team3/dev/infra/terraform.tfstate"
    region = "ap-northeast-2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"

  default_tags {
    tags = {
      Team      = "team3"
      Project   = "matnani"
      ManagedBy = "terraform"
    }
  }
}
