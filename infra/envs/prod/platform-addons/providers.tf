terraform {
  # 🚨 Prod 전용 S3 백엔드 경로 (dev와 분리)
  backend "s3" {
    bucket       = "tfstate-lionkdt5-team3"
    key          = "team3/prod/platform-addons/terraform.tfstate"
    region       = "ap-northeast-2"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 5.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.0" }
    helm       = { source = "hashicorp/helm", version = "~> 2.0" }
  }
}

provider "aws" {
  region = "ap-northeast-2"
  default_tags {
    tags = {
      Team    = var.team
      Project = var.project
      Env     = var.env
    }
  }
}

# EKS 인증 토큰 가져오기 (클러스터 이름 변수 활용)
data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

# AWS EKS 데이터 소스로 엔드포인트와 인증서 조회
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}