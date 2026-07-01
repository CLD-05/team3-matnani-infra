terraform {
  required_version = ">= 1.14.0, < 1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
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

# ACM은 CloudFront 사용을 위해 반드시 us-east-1에서 발급해야 함
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Team      = "team3"
      Project   = "matnani"
      ManagedBy = "terraform"
    }
  }
}
