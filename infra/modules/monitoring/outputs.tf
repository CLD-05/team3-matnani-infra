# modules/monitoring/output.tf

output "grafana_url" {
  description = "Grafana 접속 정보 안내"
  value       = "http://team3-matnani-grafana.${var.environment}.svc.cluster.local"
}

output "prometheus_url" {
  description = "Prometheus 접속 정보 안내"
  value       = "http://team3-matnani-prometheus.${var.environment}.svc.cluster.local"
}

output "sns_topic_arn" {
  value = aws_sns_topic.matnani_alerts.arn
}

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.eks_logs.name
}

output "prometheus_release_name" {
  value = "team3-matnani-kube-prometheus-stack"
}