# EKS 클러스터 정보를 참조하기 위한 데이터 소스
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

# 1. 관측성(모니터링) 모듈 호출
module "monitoring" {
  source       = "../../../modules/monitoring"
  cluster_name = data.aws_eks_cluster.cluster.name
  env          = var.env
}

# 2. 필수 EKS 애드온 모듈 호출
module "eks_addons" {
  source       = "../../../modules/eks-addons"
  cluster_name = data.aws_eks_cluster.cluster.name
  env          = var.env
}