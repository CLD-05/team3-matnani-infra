# modules/eks/main.tf

# 생성 리소스:
#   - aws_iam_role (cluster-role)              : EKS 클러스터 IAM Role
#   - aws_iam_role_policy_attachment (cluster) : AmazonEKSClusterPolicy 연결
#   - aws_iam_role (node-role)                 : EKS 노드그룹 IAM Role
#   - aws_iam_role_policy_attachment (node)    : WorkerNodePolicy + CNI + ECRReadOnly
#
#   - aws_security_group (node-sg)             : EKS 노드 Security Group - 노드 간 전체 통신 허용
#
#   - aws_eks_cluster                          : EKS 클러스터 v1.35
#   - aws_eks_node_group                       : 관리형 노드그룹
#   - aws_eks_access_entry                     : IAM User → EKS Access Entry
#   - aws_eks_access_policy_association        : ClusterAdmin 정책 연결

#   - aws_eks_addon (vpc-cni)                  : Pod 네트워킹 필수
#   - aws_eks_addon (coredns)                  : 클러스터 내부 DNS 필수
#   - aws_eks_addon (kube-proxy)               : 서비스 네트워킹 필수
#   - aws_eks_addon (ebs-csi)                  : EBS 동적 프로비저닝


locals {
  cluster_name = "${var.team}-${var.project}-eks"

  common_tags = {
    Team      = var.team
    Project   = var.project
    ManagedBy = "terraform"
  }
}

# IAM Cluster Role
resource "aws_iam_role" "cluster" {
  name                 = "${local.cluster_name}-cluster-role"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-cluster-role"
  })
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}



# IAM Node Role
resource "aws_iam_role" "node" {
  name                 = "${local.cluster_name}-node-role"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-node-role"
  })
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.node.name
  # ECR에서 컨테이너 이미지 pull 전용 읽기 권한
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}



# Security Group — Node
resource "aws_security_group" "node" {
  name        = "${local.cluster_name}-node-sg"
  description = "EKS Node Security Group"
  vpc_id      = var.vpc_id

  # 노드 간 전체 통신
  ingress {
    description = "Node to Node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }


  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-node-sg"
  })
}


# EKS Cluster
resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  version  = "1.35"
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [aws_security_group.node.id]
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = true
  }

  access_config {
    # API + ConfigMap 방식 — 팀원 IAM 유저 직접 매핑 가능
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  tags = merge(local.common_tags, {
    Name = local.cluster_name
  })

  depends_on = [aws_iam_role_policy_attachment.cluster]
}


# Node Group
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.cluster_name}-ng"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = var.node_instance_types

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-ng"
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr,
  ]
}

# EKS Add-ons
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  addon_version               = var.vpc_cni_version
  resolve_conflicts_on_update = "OVERWRITE"

  tags = local.common_tags
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "coredns"
  addon_version               = var.coredns_version
  resolve_conflicts_on_update = "OVERWRITE"

  tags = local.common_tags

  depends_on = [aws_eks_node_group.this]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "kube-proxy"
  addon_version               = var.kube_proxy_version
  resolve_conflicts_on_update = "OVERWRITE"

  tags = local.common_tags
}


resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "eks-pod-identity-agent"
  addon_version               = var.pod_identity_agent_version
  resolve_conflicts_on_update = "OVERWRITE"

  tags = local.common_tags
}




# 팀원 EKS 접근 — IAM 유저 직접 매핑
# 로컬에서 kubectl 바로 사용 가능
# pem 없이 각자 IAM 유저 자격증명으로 인증
resource "aws_eks_access_entry" "member" {
  for_each      = var.team_member_user_arns
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  type          = "STANDARD"

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-access-${each.key}"
  })
}

resource "aws_eks_access_policy_association" "member" {
  for_each      = var.team_member_user_arns
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# IAM에 OIDC 자격 증명 공급자 등록
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-oidc-provider"
  })
}