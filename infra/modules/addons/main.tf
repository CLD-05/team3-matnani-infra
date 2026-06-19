# infra/modules/addons/main.tf

# Helm Release 설치 목록
/*
argo-cd (7.3.1)
aws-load-balancer-controller (1.13.0)
external-secrets (0.9.18)
kube-prometheus-stack (61.3.2)
external-dns (1.14.5)
metrics-server (3.12.1)
keda (2.14.2)
*/

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
  name       = "team3-matnani-argocd"
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

# 3. ALB Controller — Ingress 감지 후 ALB 설치
resource "helm_release" "alb_controller" {
  name       = "team3-matnani-aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.13.0"
  namespace  = "kube-system"

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
  set {
    name  = "region"
    value = "ap-northeast-2"
  }
  set {
    name  = "vpcId"
    value = var.vpc_id
  }
  # featureGates 없음 — Ingress + ALB 방식

  depends_on = [kubernetes_namespace.namespaces]
  # 노드 0개 축소/복구 대비 안전장치
  wait    = true
  timeout = 600
  atomic  = true
}

# 4. AWS SSM 연동 시크릿 주입 엔진 - External Secrets Operator (ESO) 배포
resource "helm_release" "eso" {
  name       = "team3-matnani-external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.9.18"
  namespace  = "external-secrets"

  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = "external-secrets-sa"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.eso_role_arn
  }

  depends_on = [kubernetes_namespace.namespaces]
  # 노드 0개 축소/복구 대비 안전장치
  wait    = true
  timeout = 600
  atomic  = true
}

#  Prometheus + Grafana
resource "helm_release" "kube_prometheus_stack" {
  name       = "team3-matnani-kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "61.3.2"
  namespace  = "monitoring"

  depends_on = [kubernetes_namespace.namespaces]
  wait       = true
  timeout    = 600
  atomic     = true

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  # EBS CSI로 PV 생성 — ebs-csi addon이 먼저 있어야 함
  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = "gp3"
  }
  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = "10Gi" # dev: 10Gi / prod: 50Gi
  }

  # dev: 노드 공간 부족으로 pre-upgrade hook 타임아웃 방지
  set {
    name  = "prometheusOperator.admissionWebhooks.enabled"
    value = "false"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.alertmanagerConfigSelector.matchLabels.alertmanagerConfig"
    value = "team3-matnani"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.alertmanagerConfigMatcherStrategy.type"
    value = "None"
  }
}

# ExternalDNS
resource "helm_release" "external_dns" {
  name       = "team3-matnani-external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = "1.14.5"
  namespace  = "kube-system"

  depends_on = [kubernetes_namespace.namespaces]
  wait       = true
  timeout    = 300
  atomic     = true

  set {
    name  = "provider"
    value = "aws"
  }
  set {
    name  = "aws.region"
    value = "ap-northeast-2"
  }
  # dev: sync (레코드 자동 생성/삭제)
  # prod: upsert-only (실수 삭제 차단)
  set {
    name  = "policy"
    value = var.environment == "prod" ? "upsert-only" : "sync"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.external_dns_role_arn
  }
}

# metrics-server
resource "helm_release" "metrics_server" {
  name       = "team3-matnani-metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  version    = "3.12.1"
  namespace  = "kube-system"

  depends_on = [kubernetes_namespace.namespaces]
  wait       = true
  timeout    = 300
  atomic     = true
}

# KEDA
resource "helm_release" "keda" {
  name       = "team3-matnani-keda"
  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  version    = "2.14.2"
  namespace  = "kube-system"

  depends_on = [kubernetes_namespace.namespaces]
  wait       = true
  timeout    = 300
  atomic     = true
}
