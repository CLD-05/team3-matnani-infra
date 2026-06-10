# modules/monitoring/main.tf

# 1. Prometheus & Grafana 배포
resource "helm_release" "monitoring" {
  name             = "team3-matnani-monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "60.0.0"
  namespace        = "monitoring"
  create_namespace = true
  wait             = true
  timeout          = 600
  atomic           = true
  values           = [file("${path.module}/values.yaml")]

  set = [
    {
      name  = "prometheus.prometheusSpec.externalLabels.environment"
      value = var.env
    }
  ]
}

# 2. 로그 수집 파이프라인 (CloudWatch)
resource "aws_cloudwatch_log_group" "eks_logs" {
  name              = "/aws/eks/team3-matnani-${var.env}/application"
  retention_in_days = 3
}

resource "helm_release" "fluent_bit" {
  name       = "team3-matnani-fluent-bit"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  namespace  = "kube-system"

  set = [
    {
      name  = "cloudWatchLogs.region"
      value = "ap-northeast-2"
    },
    {
      name  = "cloudWatchLogs.logGroupName"
      value = aws_cloudwatch_log_group.eks_logs.name
    }
  ]
}

# 3. 알람 파이프라인 (SNS + Chatbot)
resource "aws_sns_topic" "matnani_alerts" {
  name = "team3-matnani-monitoring-alerts-${var.env}"
}

resource "aws_chatbot_slack_channel_configuration" "matnani_slack" {
  configuration_name = "team3-matnani-slack-alerts"
  iam_role_arn       = aws_iam_role.chatbot_role.arn
  slack_team_id      = var.slack_workspace_id
  slack_channel_id   = var.slack_channel_id
  sns_topic_arns     = [aws_sns_topic.matnani_alerts.arn]
}

resource "aws_iam_role" "chatbot_role" {
  name = "team3-matnani-chatbot-role-${var.env}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "chatbot.amazonaws.com" }
    }]
  })
}
# Chatbot에 필요한 최소 권한 부여
resource "aws_iam_role_policy_attachment" "chatbot_readonly" {
  role       = aws_iam_role.chatbot_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "chatbot_sns_access" {
  role       = aws_iam_role.chatbot_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSReadOnlyAccess"
}

# 4. 통합 알람 로직
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  count               = var.rds_instance_id != "" ? 1 : 0

  alarm_name          = "team3-matnani-rds-cpu-high-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "80"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "120"
  evaluation_periods  = "2"
  statistic           = "Average"

  dimensions          = { DBInstanceIdentifier = var.rds_instance_id }
  alarm_actions       = [aws_sns_topic.matnani_alerts.arn]
}