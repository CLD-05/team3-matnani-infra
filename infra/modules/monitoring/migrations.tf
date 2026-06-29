# 선택적 생성으로 전환된 기존 Dev 리소스의 state 주소를 유지합니다.
moved {
  from = helm_release.fluent_bit
  to   = helm_release.fluent_bit[0]
}

moved {
  from = kubernetes_manifest.backend_service_monitor
  to   = kubernetes_manifest.backend_service_monitor[0]
}

moved {
  from = aws_lambda_function.aiops
  to   = aws_lambda_function.aiops[0]
}

moved {
  from = aws_lambda_permission.aiops_sns
  to   = aws_lambda_permission.aiops_sns[0]
}

moved {
  from = aws_sns_topic_subscription.aiops_lambda
  to   = aws_sns_topic_subscription.aiops_lambda[0]
}

moved {
  from = aws_cloudwatch_metric_alarm.alb_target_response_time
  to   = aws_cloudwatch_metric_alarm.alb_target_response_time[0]
}

moved {
  from = aws_cloudwatch_metric_alarm.alb_http_5xx
  to   = aws_cloudwatch_metric_alarm.alb_http_5xx[0]
}

moved {
  from = aws_cloudwatch_metric_alarm.alb_http_4xx
  to   = aws_cloudwatch_metric_alarm.alb_http_4xx[0]
}

moved {
  from = aws_cloudwatch_metric_alarm.alb_unhealthy_hosts
  to   = aws_cloudwatch_metric_alarm.alb_unhealthy_hosts[0]
}

moved {
  from = aws_cloudwatch_metric_alarm.alb_request_count
  to   = aws_cloudwatch_metric_alarm.alb_request_count[0]
}

moved {
  from = aws_cloudwatch_metric_alarm.eks_node_cpu
  to   = aws_cloudwatch_metric_alarm.eks_node_cpu[0]
}

moved {
  from = aws_cloudwatch_metric_alarm.eks_node_memory
  to   = aws_cloudwatch_metric_alarm.eks_node_memory[0]
}

moved {
  from = aws_cloudwatch_metric_alarm.nat_gw_connection_count
  to   = aws_cloudwatch_metric_alarm.nat_gw_connection_count["0"]
}

moved {
  from = aws_cloudwatch_metric_alarm.nat_gw_error_port_allocation
  to   = aws_cloudwatch_metric_alarm.nat_gw_error_port_allocation["0"]
}

moved {
  from = aws_cloudwatch_metric_alarm.nat_gw_bytes_out_to_destination
  to   = aws_cloudwatch_metric_alarm.nat_gw_bytes_out_to_destination["0"]
}
