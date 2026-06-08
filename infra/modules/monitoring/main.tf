# modules/monitoring/main.tf

# 1. prometheus & Grafana 배포
resource "helm_release" "monitoring" {
  name       = "team3-matnani-monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "60.0.0"
  namespace  = "monitoring"
  create_namespace = true #네임스페이스 자동 생성 추가

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
# 2. 로그 수집 파이프라인 ( Cloudwatch )
resource "aws_cloudwatch_log_group" "eks_logs" {
  name = "/aws/eks/team3-matnani-${var.environment}/application"
  retention_in_days = 3
}

resource "helm_release" "fluent_bit" {
  name       = "aws-for-fluent-bit"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  namespace  = "kube-system"

  set {
    name  = "cloudWatchLogs.region"
    value = "ap-northeast-2"
  }
  set {
    name  = "cloudWatchLogs.logGroupName"
    value = aws_cloudwatch_log_group.eks_logs.name
  }
}

# 알람 파이프라인 ( SNS + Chatbot )
resource "aws_sns_topic" "matnani_alerts" {
  name = "matnani-monitoring-alerts-${var.environment}"
}

# AWS Chatbot 연동 (Slack)
resource "aws_chatbot_slack_channel_configuration" "matnani_slack" {
  configuration_name = "matnani-slack-alerts"
  iam_role_arn       = aws_iam_role.chatbot_role.arn
  slack_team_id      = var.slack_workspace_id
  slack_channel_id   = var.slack_channel_id
  sns_topic_arns     = [aws_sns_topic.matnani_alerts.arn]
}


# Chatbot을 위한 최소 권한 IAM Role
resource "aws_iam_role" "chatbot_role" {
  name = "matnani-chatbot-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "chatbot.amazonaws.com" }
    }]
  })
}