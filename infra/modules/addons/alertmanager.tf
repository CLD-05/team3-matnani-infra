# SSM Parameter Store values are synchronized by ESO without exposing the
# Slack Webhook URL in Terraform configuration or state.
resource "kubernetes_manifest" "aws_parameter_store" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "aws-parameter-store"
    }
    spec = {
      provider = {
        aws = {
          service = "ParameterStore"
          region  = "ap-northeast-2"
        }
      }
    }
  }

  depends_on = [helm_release.eso]
}

resource "kubernetes_manifest" "alertmanager_slack_webhook" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "alertmanager-slack-webhook"
      namespace = "monitoring"
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        kind = "ClusterSecretStore"
        name = "aws-parameter-store"
      }
      target = {
        name           = "alertmanager-slack-webhook"
        creationPolicy = "Owner"
      }
      data = [{
        secretKey = "webhook-url"
        remoteRef = {
          key = "/${var.team}/${var.project}/${var.env}/monitoring/slack-webhook"
        }
      }]
    }
  }

  depends_on = [kubernetes_manifest.aws_parameter_store]
}

resource "kubernetes_manifest" "alertmanager_slack" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1alpha1"
    kind       = "AlertmanagerConfig"
    metadata = {
      name      = "team3-matnani-slack"
      namespace = "monitoring"
      labels = {
        alertmanagerConfig = "team3-matnani"
      }
    }
    spec = {
      route = {
        receiver       = "slack"
        groupBy        = ["namespace", "alertname"]
        groupWait      = "30s"
        groupInterval  = "5m"
        repeatInterval = "4h"
        matchers = [{
          name  = "severity"
          value = "warning|critical"
          regex = true
        }]
      }
      receivers = [{
        name = "slack"
        slackConfigs = [{
          apiURL = {
            name = "alertmanager-slack-webhook"
            key  = "webhook-url"
          }
          sendResolved = true
          title        = "[{{ .Status | toUpper }}] {{ .CommonLabels.alertname }}"
          text         = "{{ range .Alerts }}*Summary:* {{ .Annotations.summary }}\n*Description:* {{ .Annotations.description }}\n*Namespace:* {{ .Labels.namespace }}\n*Severity:* {{ .Labels.severity }}\n{{ end }}"
        }]
      }]
    }
  }

  depends_on = [
    helm_release.kube_prometheus_stack,
    kubernetes_manifest.alertmanager_slack_webhook,
  ]
}
