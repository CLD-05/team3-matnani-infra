# modules/monitoring/output.tf

output "grafana_url" {
  description = "Grafana 접속 정보 안내"
  value       = "http://team3-matnani-grafana.${var.environment}.svc.cluster.local"
}

output "prometheus_url" {
  description = "Prometheus 접속 정보 안내"
  value       = "http://team3-matnani-prometheus.${var.environment}.svc.cluster.local"
}