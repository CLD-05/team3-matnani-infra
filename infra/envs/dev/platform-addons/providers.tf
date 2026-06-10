terraform {
  required_providers {
    aws        = {
      source = "hashicorp/aws", version = "~> 5.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes", version = "~> 2.0"
    }
    helm       = {
      source = "hashicorp/helm", version = "~> 2.0"
    }
  }
}
provider "aws" {
  region = "ap-northeast-2"
  default_tags {
    tags = {
      Team = "team3"
    }
  }
}

# EKS 연결 설정
data "aws_eks_cluster_auth" "cluster" {
  name = local.cluster_name
}

provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = base64decode(local.cluster_ca)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = base64decode(local.cluster_ca)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}