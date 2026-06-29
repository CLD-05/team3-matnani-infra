# modules/monitoring/servicemonitors.tf

# 백엔드 앱용 ServiceMonitor
resource "kubernetes_manifest" "backend_service_monitor" {
  count = var.enable_cluster_resources ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "team3-matnani-backend-sm"
      namespace = "monitoring"
      labels    = { release = "team3-matnani-kube-prometheus-stack" }
    }
    spec = {
      selector  = { matchLabels = { app = "team3-matnani-backend" } }
      endpoints = [{ port = "http", path = "/actuator/prometheus" }]
    }
  }

  # 기존 별도 Helm 릴리스를 사용할 때의 의존성입니다.
  # depends_on = [helm_release.monitoring]
}
