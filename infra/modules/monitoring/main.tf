# infra/modules/monitoring/main.tf

# 로그 및 알람 파이프라인
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

# SNS Topic (알람 수신)
resource "aws_sns_topic" "matnani_alerts" {
  name = "team3-matnani-${var.env}-monitoring-alerts"
}

# ======== AIOps — Bedrock Claude 장애 자동 분석 ========

data "aws_caller_identity" "current" {}

data "archive_file" "aiops_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/alarm_analyzer.py"
  output_path = "${path.module}/lambda/alarm_analyzer.zip"
}

resource "aws_iam_role" "aiops_lambda" {
  name                 = "team3-matnani-${var.env}-aiops-lambda-role"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "aiops_lambda" {
  name = "team3-matnani-${var.env}-aiops-lambda-policy"
  role = aws_iam_role.aiops_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:ap-northeast-2:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = "arn:aws:bedrock:ap-northeast-2::foundation-model/anthropic.claude-3-5-haiku-20241022-v1:0"
      }
    ]
  })
}

resource "aws_lambda_function" "aiops" {
  function_name    = "team3-matnani-${var.env}-aiops-alarm-analyzer"
  role             = aws_iam_role.aiops_lambda.arn
  filename         = data.archive_file.aiops_lambda.output_path
  source_code_hash = data.archive_file.aiops_lambda.output_base64sha256
  handler          = "alarm_analyzer.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }
}

resource "aws_lambda_permission" "aiops_sns" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.aiops.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.matnani_alerts.arn
}

resource "aws_sns_topic_subscription" "aiops_lambda" {
  topic_arn = aws_sns_topic.matnani_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.aiops.arn
}

# Amazon Q Developer in chat applications가 SNS 알림을 Slack으로 전달합니다.
resource "aws_chatbot_slack_channel_configuration" "matnani_slack" {
  configuration_name = "team3-matnani-slack-alerts"
  iam_role_arn       = var.chatbot_role_arn
  slack_team_id      = var.slack_workspace_id
  slack_channel_id   = var.slack_channel_id
  sns_topic_arns     = [aws_sns_topic.matnani_alerts.arn]
}

/*
# 기존 Terraform 직접 생성 방식입니다.
# Chatbot 전용 Role은 Permissions Boundary를 적용해 AWS CLI로 생성했으므로
# Terraform에서 중복 생성하지 않고 chatbot_role_arn으로 전달합니다.
resource "aws_iam_role" "chatbot_role" {
  name = "team3-matnani-${var.env}-chatbot-role"
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
  role       = aws_iam_role.chatbot_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "chatbot_sns_access" {
  role       = aws_iam_role.chatbot_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSReadOnlyAccess"
}
*/



# ========= RDS Alarms ==========

# RDS CPU 사용률
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "team3-matnani-${var.env}-rds-cpu-high"
  alarm_description   = "RDS CPU utilization exceeded 80% for 2 minutes"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.rds_cpu_threshold
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "120"
  evaluation_periods  = "2"
  statistic           = "Average"
  dimensions          = { DBInstanceIdentifier = var.rds_instance_id }
  alarm_actions       = [aws_sns_topic.matnani_alerts.arn]
}

# RDS 데이터베이스 연결 수
resource "aws_cloudwatch_metric_alarm" "rds_database_connections" {
  alarm_name          = "team3-matnani-${var.env}-rds-db-connections"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  threshold           = var.rds_connections_threshold
  comparison_operator = "GreaterThanThreshold"
  period              = "60"
  evaluation_periods  = "1"
  statistic           = "Average"
  dimensions          = { DBInstanceIdentifier = var.rds_instance_id }
  alarm_actions       = [aws_sns_topic.matnani_alerts.arn]
  treat_missing_data  = "notBreaching"
}

# RDS 읽기 지연시간
resource "aws_cloudwatch_metric_alarm" "rds_read_latency" {
  alarm_name          = "team3-matnani-${var.env}-rds-read-latency"
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  threshold           = var.rds_read_latency_threshold
  comparison_operator = "GreaterThanThreshold"
  period              = "60"
  evaluation_periods  = "2"
  statistic           = "Average"
  dimensions          = { DBInstanceIdentifier = var.rds_instance_id }
  alarm_actions       = [aws_sns_topic.matnani_alerts.arn]
  treat_missing_data  = "notBreaching"
}

# RDS 쓰기 지연시간
resource "aws_cloudwatch_metric_alarm" "rds_write_latency" {
  alarm_name          = "team3-matnani-${var.env}-rds-write-latency"
  metric_name         = "WriteLatency"
  namespace           = "AWS/RDS"
  threshold           = var.rds_write_latency_threshold
  comparison_operator = "GreaterThanThreshold"
  period              = "60"
  evaluation_periods  = "2"
  statistic           = "Average"
  dimensions          = { DBInstanceIdentifier = var.rds_instance_id }
  alarm_actions       = [aws_sns_topic.matnani_alerts.arn]
  treat_missing_data  = "notBreaching"
}

# RDS 스토리지 공간 부족
resource "aws_cloudwatch_metric_alarm" "rds_free_storage_space" {
  alarm_name          = "team3-matnani-${var.env}-rds-free-storage"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  threshold           = var.rds_free_storage_threshold_bytes
  comparison_operator = "LessThanThreshold"
  period              = "300"
  evaluation_periods  = "1"
  statistic           = "Average"
  dimensions          = { DBInstanceIdentifier = var.rds_instance_id }
  alarm_actions       = [aws_sns_topic.matnani_alerts.arn]
  treat_missing_data  = "notBreaching"
}



# ======== NAT Gateway Alarms =======

# NAT Gateway 연결 수 (55,000으로 제한함)
resource "aws_cloudwatch_metric_alarm" "nat_gw_connection_count" {
  alarm_name          = "team3-matnani-${var.env}-nat-gw-connection-count"
  metric_name         = "ConnectionCount"
  namespace           = "AWS/NatGateway"
  threshold           = var.nat_gw_connection_count_threshold
  comparison_operator = "GreaterThanThreshold"
  period              = "60"
  evaluation_periods  = "1"
  statistic           = "Maximum"
  dimensions          = { NatGatewayId = var.nat_gateway_id[0] }
  alarm_actions       = [aws_sns_topic.matnani_alerts.arn]
  treat_missing_data  = "notBreaching"
}

# NAT Gateway 에러 (포트 할당 실패)
resource "aws_cloudwatch_metric_alarm" "nat_gw_error_port_allocation" {
  alarm_name          = "team3-matnani-${var.env}-nat-gw-port-alloc-error"
  metric_name         = "ErrorPortAllocation"
  namespace           = "AWS/NatGateway"
  threshold           = "10"
  comparison_operator = "GreaterThanThreshold"
  period              = "60"
  evaluation_periods  = "1"
  statistic           = "Sum"
  dimensions          = { NatGatewayId = var.nat_gateway_id[0] }
  alarm_actions       = [aws_sns_topic.matnani_alerts.arn]
  treat_missing_data  = "notBreaching"
}

# NAT Gateway 바이트 출력
resource "aws_cloudwatch_metric_alarm" "nat_gw_bytes_out_to_destination" {
  alarm_name          = "team3-matnani-${var.env}-nat-gw-bytes-out"
  metric_name         = "BytesOutToDestination"
  namespace           = "AWS/NatGateway"
  threshold           = "10737418240"
  comparison_operator = "GreaterThanThreshold"
  period              = "300"
  evaluation_periods  = "2"
  statistic           = "Sum"
  dimensions          = { NatGatewayId = var.nat_gateway_id[0] }
  alarm_actions       = [aws_sns_topic.matnani_alerts.arn]
  treat_missing_data  = "notBreaching"
}


# ======== ElastiCache (Redis) Alarms ========

# Redis CPU 사용률
resource "aws_cloudwatch_metric_alarm" "redis_cpu_high" {
  count = var.redis_cluster_id != "" ? 1 : 0

  alarm_name          = "team3-matnani-${var.env}-redis-cpu-high"
  alarm_description   = "Redis CPU utilization exceeded ${var.redis_cpu_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.redis_cpu_threshold
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "120"
  evaluation_periods  = "2"
  statistic           = "Average"
  dimensions          = { CacheClusterId = var.redis_cluster_id }
  alarm_actions       = [aws_sns_topic.matnani_alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "redis_connections_high" {
  count = var.redis_cluster_id != "" ? 1 : 0

  alarm_name          = "team3-matnani-${var.env}-redis-connections-high"
  alarm_description   = "Redis current connections exceeded ${var.redis_connections_threshold}"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.redis_connections_threshold
  metric_name         = "CurrConnections"
  namespace           = "AWS/ElastiCache"
  period              = "60"
  evaluation_periods  = "2"
  statistic           = "Average"
  dimensions          = { CacheClusterId = var.redis_cluster_id }
  alarm_actions       = [aws_sns_topic.matnani_alerts.arn]
  treat_missing_data  = "notBreaching"
}


# ======== EKS Alarms  =========

# EKS 노드 CPU 사용률
resource "aws_cloudwatch_metric_alarm" "eks_node_cpu" {
  alarm_name          = "team3-matnani-${var.env}-eks-node-cpu"
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  threshold           = var.eks_node_cpu_threshold
  comparison_operator = "GreaterThanThreshold"
  period              = "300"
  evaluation_periods  = "2"
  statistic           = "Average"
  dimensions          = { ClusterName = var.eks_cluster_name }
  alarm_actions       = [aws_sns_topic.matnani_alerts.arn]
  treat_missing_data  = "notBreaching"
}

# EKS 노드 메모리 사용률
resource "aws_cloudwatch_metric_alarm" "eks_node_memory" {
  alarm_name          = "team3-matnani-${var.env}-eks-node-memory"
  metric_name         = "node_memory_utilization"
  namespace           = "ContainerInsights"
  threshold           = var.eks_node_memory_threshold
  comparison_operator = "GreaterThanThreshold"
  period              = "300"
  evaluation_periods  = "2"
  statistic           = "Average"
  dimensions          = { ClusterName = var.eks_cluster_name }
  alarm_actions       = [aws_sns_topic.matnani_alerts.arn]
  treat_missing_data  = "notBreaching"
}


# ========== ALB Alarms ==========


# ALB 타겟 응답시간 (성능)
resource "aws_cloudwatch_metric_alarm" "alb_target_response_time" {
  alarm_name          = "team3-matnani-${var.env}-alb-response-time"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  threshold           = "1"
  comparison_operator = "GreaterThanThreshold"
  period              = "60"
  evaluation_periods  = "2"
  statistic           = "Average"
  dimensions          = { LoadBalancer = var.alb_name }
  alarm_actions       = [aws_sns_topic.matnani_alerts.arn]
  treat_missing_data  = "notBreaching"
}

# ALB HTTP 5XX 에러
resource "aws_cloudwatch_metric_alarm" "alb_http_5xx" {
  alarm_name          = "team3-matnani-${var.env}-alb-http-5xx"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  threshold           = var.alb_http_5xx_threshold
  comparison_operator = "GreaterThanThreshold"
  period              = "60"
  evaluation_periods  = "1"
  statistic           = "Sum"
  dimensions          = { LoadBalancer = var.alb_name }
  alarm_actions       = [aws_sns_topic.matnani_alerts.arn]
  treat_missing_data  = "notBreaching"
}

# ALB HTTP 4XX 에러
resource "aws_cloudwatch_metric_alarm" "alb_http_4xx" {
  alarm_name          = "team3-matnani-${var.env}-alb-http-4xx"
  metric_name         = "HTTPCode_Target_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  threshold           = var.alb_http_4xx_threshold
  comparison_operator = "GreaterThanThreshold"
  period              = "60"
  evaluation_periods  = "2"
  statistic           = "Sum"
  dimensions          = { LoadBalancer = var.alb_name }
  alarm_actions       = [aws_sns_topic.matnani_alerts.arn]
  treat_missing_data  = "notBreaching"
}

# ALB 언헬시 호스트
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "team3-matnani-${var.env}-alb-unhealthy-hosts"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  threshold           = "1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  period              = "60"
  evaluation_periods  = "1"
  statistic           = "Average"
  dimensions = {
    LoadBalancer = var.alb_name
    TargetGroup  = var.target_group_name
  }
  alarm_actions      = [aws_sns_topic.matnani_alerts.arn]
  treat_missing_data = "notBreaching"
}

# ALB 요청 수 (부하 지표)
resource "aws_cloudwatch_metric_alarm" "alb_request_count" {
  alarm_name          = "team3-matnani-${var.env}-alb-request-count"
  metric_name         = "RequestCount"
  namespace           = "AWS/ApplicationELB"
  threshold           = var.alb_request_count_threshold
  comparison_operator = "GreaterThanThreshold"
  period              = "60"
  evaluation_periods  = "2"
  statistic           = "Sum"
  dimensions          = { LoadBalancer = var.alb_name }
  alarm_actions       = [aws_sns_topic.matnani_alerts.arn]
  treat_missing_data  = "notBreaching"
}
