# infra/envs/dev/fis/cloudwatch.tf
#
# FIS 실험 자동 중단 조건용 CloudWatch 알람

# 1. EKS 정상 노드 수 하한선
#    노드 수가 1 이하로 떨어지면 알람 → 실험 자동 중단
resource "aws_cloudwatch_metric_alarm" "fis_eks_node_count" {
  alarm_name          = "${local.prefix}-fis-eks-node-count"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "GroupInServiceInstances"
  namespace           = "AWS/AutoScaling"
  period              = 60
  statistic           = "Average"
  threshold           = 2
  alarm_description   = "FIS 실험 중단 조건: EKS 정상 노드 수 2 미만"
  treat_missing_data  = "breaching"

  dimensions = {
    AutoScalingGroupName = data.aws_eks_node_group.main.resources[0].autoscaling_groups[0].name
  }

  tags = {
    Name        = "${local.prefix}-fis-eks-node-count"
    Environment = var.env
    Team        = var.team
  }
}

# 2. ALB 5xx 에러율
#    5분간 5xx 에러 10건 초과 시 알람 → 실험 자동 중단
resource "aws_cloudwatch_metric_alarm" "fis_alb_5xx" {
  alarm_name          = "${local.prefix}-fis-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "FIS 실험 중단 조건: 5분간 5xx 에러 10건 초과"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = data.aws_lb.main.arn_suffix
  }

  tags = {
    Name        = "${local.prefix}-fis-alb-5xx"
    Environment = var.env
    Team        = var.team
  }
}

# 3. ALB p95 응답 지연
#    p95 응답시간 3초 초과 시 알람 → 실험 자동 중단
resource "aws_cloudwatch_metric_alarm" "fis_alb_p95_latency" {
  alarm_name          = "${local.prefix}-fis-alb-p95-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  extended_statistic  = "p95"
  threshold           = 3
  alarm_description   = "FIS 실험 중단 조건: ALB p95 응답 지연 3초 초과"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = data.aws_lb.main.arn_suffix
  }

  tags = {
    Name        = "${local.prefix}-fis-alb-p95-latency"
    Environment = var.env
    Team        = var.team
  }
}
