# modules/monitoring/main.tf

resource "helm_release" "monitoring" {
  name       = "team3-matnani-monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "60.0.0"
  namespace  = "monitoring"

  # 가이드라인: 배포 안정성 확보
  wait    = true
  timeout = 600
  atomic  = true

  # 가이드라인: 설정 격리 (설정은 values.yaml에서 관리)
  values = [
    file("${path.module}/values.yaml")
  ]

  # 환경별 태그/설정 주입이 필요하면 아래와 같이 추가
  set {
    name  = "prometheus.prometheusSpec.externalLabels.environment"
    value = var.environment
  }
}