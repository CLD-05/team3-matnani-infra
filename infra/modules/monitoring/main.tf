# Existing kube-prometheus-stack is managed outside this module.
# Keep this module limited to resources that can coexist with that stack.

# 2. 로그 및 알람 파이프라인
resource "aws_cloudwatch_log_group" "eks_logs" {
  name              = "/aws/eks/team3-matnani-${var.env}/application"
  retention_in_days = 3
}

resource "helm_release" "fluent_bit" {
  name       = "team3-matnani-${var.env}-fluent-bit"
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

resource "aws_sns_topic" "matnani_alerts" {
  name = "team3-matnani-${var.env}-monitoring-alerts"
}

resource "aws_chatbot_slack_channel_configuration" "matnani_slack" {
  count = var.enable_chatbot ? 1 : 0

  configuration_name = "team3-matnani-slack-alerts"
  iam_role_arn       = aws_iam_role.chatbot_role[0].arn
  slack_team_id      = var.slack_workspace_id
  slack_channel_id   = var.slack_channel_id
  sns_topic_arns     = [aws_sns_topic.matnani_alerts.arn]
}

resource "aws_iam_role" "chatbot_role" {
  count = var.enable_chatbot ? 1 : 0

  name                 = "team3-matnani-${var.env}-chatbot-role"
  permissions_boundary = var.permissions_boundary
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "chatbot.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "chatbot_readonly" {
  count = var.enable_chatbot ? 1 : 0

  role       = aws_iam_role.chatbot_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "chatbot_sns_access" {
  count = var.enable_chatbot ? 1 : 0

  role       = aws_iam_role.chatbot_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSReadOnlyAccess"
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "team3-matnani-${var.env}-rds-cpu-high"
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
