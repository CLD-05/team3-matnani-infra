# modules/monitoring/servicemonitors.tf

# 백엔드 앱용 ServiceMonitor
resource "kubernetes_manifest" "backend_service_monitor" {
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

}
