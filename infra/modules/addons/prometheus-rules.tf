locals {
  alert_namespace           = "matnani"
  pod_cpu_threshold         = var.environment == "prod" ? 80 : 75
  pod_memory_threshold      = var.environment == "prod" ? 85 : 80
  node_cpu_threshold        = var.environment == "prod" ? 80 : 75
  node_memory_threshold     = var.environment == "prod" ? 80 : 75
  backend_5xx_rate          = var.environment == "prod" ? 0.03 : 0.05
  backend_response_seconds  = var.environment == "prod" ? 0.8 : 1
  redis_cpu_threshold       = var.environment == "prod" ? 70 : 50
  redis_connections_threshold = var.environment == "prod" ? 50 : 10
}

resource "kubernetes_manifest" "matnani_prometheus_rules" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "team3-matnani-alerts"
      namespace = "monitoring"
      labels = {
        release = "team3-matnani-kube-prometheus-stack"
      }
    }
    spec = {
      groups = [
        {
          name = "matnani-kubernetes"
          rules = [
            {
              alert = "MatnaniPodCpuHigh"
              expr  = "100 * sum by (namespace, pod) (rate(container_cpu_usage_seconds_total{namespace=\"${local.alert_namespace}\", container!=\"\", image!=\"\"}[5m])) / clamp_min(sum by (namespace, pod) (kube_pod_container_resource_requests{namespace=\"${local.alert_namespace}\", resource=\"cpu\", unit=\"core\"}), 0.001) > ${local.pod_cpu_threshold}"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "Pod CPU usage is high"
                description = "Pod {{ $labels.pod }} CPU usage has exceeded ${local.pod_cpu_threshold}% of its requested CPU for 5 minutes."
              }
            },
            {
              alert = "MatnaniPodMemoryHigh"
              expr  = "100 * sum by (namespace, pod) (container_memory_working_set_bytes{namespace=\"${local.alert_namespace}\", container!=\"\", image!=\"\"}) / clamp_min(sum by (namespace, pod) (kube_pod_container_resource_requests{namespace=\"${local.alert_namespace}\", resource=\"memory\", unit=\"byte\"}), 1) > ${local.pod_memory_threshold}"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "Pod memory usage is high"
                description = "Pod {{ $labels.pod }} memory usage has exceeded ${local.pod_memory_threshold}% of its requested memory for 5 minutes."
              }
            },
            {
              alert = "MatnaniNodeCpuHigh"
              expr  = "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100) > ${local.node_cpu_threshold}"
              for   = "10m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "Node CPU usage is high"
                description = "Node {{ $labels.instance }} CPU usage has exceeded ${local.node_cpu_threshold}% for 10 minutes."
              }
            },
            {
              alert = "MatnaniNodeMemoryHigh"
              expr  = "100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) > ${local.node_memory_threshold}"
              for   = "10m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "Node memory usage is high"
                description = "Node {{ $labels.instance }} memory usage has exceeded ${local.node_memory_threshold}% for 10 minutes."
              }
            },
            {
              alert = "MatnaniContainerRestarting"
              expr  = "increase(kube_pod_container_status_restarts_total{namespace=\"${local.alert_namespace}\"}[10m]) > 0"
              for   = "1m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "Container restarted"
                description = "Container {{ $labels.container }} in pod {{ $labels.pod }} restarted during the last 10 minutes."
              }
            },
            {
              alert = "MatnaniPodPending"
              expr  = "sum by (namespace, pod) (kube_pod_status_phase{namespace=\"${local.alert_namespace}\", phase=\"Pending\"} == 1) > 0"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "Pod remains Pending"
                description = "Pod {{ $labels.pod }} has remained Pending for more than 5 minutes."
              }
            },
            {
              alert = "MatnaniPodCrashLoopBackOff"
              expr  = "max_over_time(kube_pod_container_status_waiting_reason{namespace=\"${local.alert_namespace}\", reason=\"CrashLoopBackOff\"}[5m]) >= 1"
              for   = "2m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "Pod is in CrashLoopBackOff"
                description = "Container {{ $labels.container }} in pod {{ $labels.pod }} is repeatedly crashing."
              }
            }
          ]
        },
        {
          name = "matnani-application"
          rules = [
            {
              alert = "MatnaniBackendHigh5xxRate"
              expr  = "sum(rate(http_server_requests_seconds_count{namespace=\"${local.alert_namespace}\", status=~\"5..\"}[5m])) / clamp_min(sum(rate(http_server_requests_seconds_count{namespace=\"${local.alert_namespace}\"}[5m])), 0.001) > ${local.backend_5xx_rate}"
              for   = "5m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "Backend 5xx error rate is high"
                description = "Backend 5xx responses have exceeded ${local.backend_5xx_rate * 100}% for 5 minutes."
              }
            },
            {
              alert = "MatnaniBackendSlowResponses"
              expr  = "sum(rate(http_server_requests_seconds_sum{namespace=\"${local.alert_namespace}\"}[5m])) / clamp_min(sum(rate(http_server_requests_seconds_count{namespace=\"${local.alert_namespace}\"}[5m])), 0.001) > ${local.backend_response_seconds}"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "Backend response time is high"
                description = "Average backend response time has exceeded ${local.backend_response_seconds} seconds for 5 minutes."
              }
            }
          ]
        }
      ]
    }
  }

  depends_on = [helm_release.kube_prometheus_stack]
}
