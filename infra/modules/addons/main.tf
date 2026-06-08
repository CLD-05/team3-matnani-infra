# 1. 공통 격리 네임스페이스 일괄 생성
resource "kubernetes_namespace" "namespaces" {
  for_each = toset(["argocd", "monitoring", "external-secrets", "matnani"])

  metadata {
    name = each.key
    labels = {
      "managed-by"  = "terraform"
      "Team"        = "team3"
      "project"     = "matnani"
      "environment" = var.environment
    }
  }
}

# 2. GitOps 핵심 엔진 - ArgoCD 배포
resource "helm_release" "argocd" {
  name       = "team3-argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.3.1"
  namespace  = "argocd"

  depends_on = [kubernetes_namespace.namespaces]

  # 노드 0개 축소/복구 대비 안전장치
  wait    = true
  timeout = 600
  atomic  = true

  set {
    name  = "server.insecure"
    value = "true"
  }
  set {
    name  = "server.configs.cm.timeout.reconciliation"
    value = "180s" # 단일 main 브랜치 감지 최적화 타임아웃
  }
}

# 3. 인그레스 제어 엔진 - AWS Load Balancer Controller 배포
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.7.2"
  namespace  = "kube-system"

  # 노드 0개 축소/복구 대비 안전장치
  wait    = true
  timeout = 600
  atomic  = true

  set {
    name  = "clusterName"
    value = var.cluster_name
  }
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.alb_controller_role_arn
  }
}

# 4. AWS SSM 연동 시크릿 주입 엔진 - External Secrets Operator (ESO) 배포
resource "helm_release" "eso" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.9.18"
  namespace  = "external-secrets"

  depends_on = [kubernetes_namespace.namespaces]

  # 노드 0개 축소/복구 대비 안전장치
  wait    = true
  timeout = 600
  atomic  = true
}