# infra/envs/dev/monitoring/main.tf
# CloudWatch 알람만 생성 (SNS, Chatbot은 수동 생성된 리소스 참조)

data "aws_sns_topic" "alerts" {
  name = "${var.team}-${var.project}-${var.env}-monitoring-alerts"
}

data "aws_vpc" "main" {
  tags = {
    Team    = var.team
    Name    = "${var.team}-${var.project}-${var.env}-vpc"
  }
}

data "aws_nat_gateways" "main" {
  vpc_id = data.aws_vpc.main.id
  filter {
    name   = "state"
    values = ["available"]
  }
}


# ======== RDS Alarms ========

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.team}-${var.project}-${var.env}-rds-cpu-high"
  alarm_description   = "RDS CPU utilization exceeded 80%"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "120"
  evaluation_periods  = "2"
  statistic           = "Average"
  dimensions          = { DBInstanceIdentifier = var.rds_instance_id }
  alarm_actions       = [data.aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${var.team}-${var.project}-${var.env}-rds-db-connections"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  period              = "60"
  evaluation_periods  = "1"
  statistic           = "Average"
  dimensions          = { DBInstanceIdentifier = var.rds_instance_id }
  alarm_actions       = [data.aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "rds_read_latency" {
  alarm_name          = "${var.team}-${var.project}-${var.env}-rds-read-latency"
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  threshold           = 0.1
  comparison_operator = "GreaterThanThreshold"
  period              = "60"
  evaluation_periods  = "2"
  statistic           = "Average"
  dimensions          = { DBInstanceIdentifier = var.rds_instance_id }
  alarm_actions       = [data.aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "rds_write_latency" {
  alarm_name          = "${var.team}-${var.project}-${var.env}-rds-write-latency"
  metric_name         = "WriteLatency"
  namespace           = "AWS/RDS"
  threshold           = 0.12
  comparison_operator = "GreaterThanThreshold"
  period              = "60"
  evaluation_periods  = "2"
  statistic           = "Average"
  dimensions          = { DBInstanceIdentifier = var.rds_instance_id }
  alarm_actions       = [data.aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name          = "${var.team}-${var.project}-${var.env}-rds-free-storage"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  threshold           = 32212254720 # 30GB
  comparison_operator = "LessThanThreshold"
  period              = "300"
  evaluation_periods  = "1"
  statistic           = "Average"
  dimensions          = { DBInstanceIdentifier = var.rds_instance_id }
  alarm_actions       = [data.aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
}

# ======== ElastiCache (Redis) Alarms ========

resource "aws_cloudwatch_metric_alarm" "redis_cpu_high" {
  alarm_name          = "${var.team}-${var.project}-${var.env}-redis-cpu-high"
  alarm_description   = "Redis CPU utilization exceeded 50%"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 50
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "120"
  evaluation_periods  = "2"
  statistic           = "Average"
  dimensions          = { CacheClusterId = var.redis_cluster_id }
  alarm_actions       = [data.aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "redis_connections_high" {
  alarm_name          = "${var.team}-${var.project}-${var.env}-redis-connections-high"
  alarm_description   = "Redis current connections exceeded 10"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 10
  metric_name         = "CurrConnections"
  namespace           = "AWS/ElastiCache"
  period              = "60"
  evaluation_periods  = "2"
  statistic           = "Average"
  dimensions          = { CacheClusterId = var.redis_cluster_id }
  alarm_actions       = [data.aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
}

# ======== NAT Gateway Alarms ========

resource "aws_cloudwatch_metric_alarm" "nat_gw_connection_count" {
  alarm_name          = "${var.team}-${var.project}-${var.env}-nat-gw-connection-count"
  metric_name         = "ConnectionCount"
  namespace           = "AWS/NatGateway"
  threshold           = 50000
  comparison_operator = "GreaterThanThreshold"
  period              = "60"
  evaluation_periods  = "1"
  statistic           = "Maximum"
  dimensions          = { NatGatewayId = tolist(data.aws_nat_gateways.main.ids)[0] }
  alarm_actions       = [data.aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "nat_gw_error_port_allocation" {
  alarm_name          = "${var.team}-${var.project}-${var.env}-nat-gw-port-alloc-error"
  metric_name         = "ErrorPortAllocation"
  namespace           = "AWS/NatGateway"
  threshold           = 10
  comparison_operator = "GreaterThanThreshold"
  period              = "60"
  evaluation_periods  = "1"
  statistic           = "Sum"
  dimensions          = { NatGatewayId = tolist(data.aws_nat_gateways.main.ids)[0] }
  alarm_actions       = [data.aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "nat_gw_bytes_out" {
  alarm_name          = "${var.team}-${var.project}-${var.env}-nat-gw-bytes-out"
  metric_name         = "BytesOutToDestination"
  namespace           = "AWS/NatGateway"
  threshold           = 10737418240 # 10GB
  comparison_operator = "GreaterThanThreshold"
  period              = "300"
  evaluation_periods  = "2"
  statistic           = "Sum"
  dimensions          = { NatGatewayId = tolist(data.aws_nat_gateways.main.ids)[0] }
  alarm_actions       = [data.aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
}

# ======== EKS Alarms ========

resource "aws_cloudwatch_metric_alarm" "eks_node_cpu" {
  alarm_name          = "${var.team}-${var.project}-${var.env}-eks-node-cpu"
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  threshold           = 70
  comparison_operator = "GreaterThanThreshold"
  period              = "300"
  evaluation_periods  = "2"
  statistic           = "Average"
  dimensions          = { ClusterName = var.eks_cluster_name }
  alarm_actions       = [data.aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "eks_node_memory" {
  alarm_name          = "${var.team}-${var.project}-${var.env}-eks-node-memory"
  metric_name         = "node_memory_utilization"
  namespace           = "ContainerInsights"
  threshold           = 65
  comparison_operator = "GreaterThanThreshold"
  period              = "300"
  evaluation_periods  = "2"
  statistic           = "Average"
  dimensions          = { ClusterName = var.eks_cluster_name }
  alarm_actions       = [data.aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
}

# ALB 알람은 ALB ARN suffix 확인 후 추가 예정
# aws elbv2 describe-load-balancers --profile team3-lsh 로 ARN suffix 확인
