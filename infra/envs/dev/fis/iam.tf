# infra/envs/dev/fis/iam.tf
#
# FIS IAM Role은 TeamRuntimeBoundary 제약으로 GHA에서 생성 불가
# → CLI로 사전 생성 후 data source로 참조
#
# 사전 생성 명령 (팀 계정으로 1회 실행):
#   aws iam create-role \
#     --role-name team3-matnani-dev-fis-role \
#     --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"fis.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
#     --permissions-boundary arn:aws:iam::495599735720:policy/TeamRuntimeBoundary

data "aws_iam_role" "fis" {
  name = "${local.prefix}-fis-role"
}

resource "aws_iam_role_policy" "fis" {
  name = "${local.prefix}-fis-policy"
  role = data.aws_iam_role.fis.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # EC2 (EKS 노드 종료, CPU 스트레스 타겟)
          "ec2:DescribeInstances",
          "ec2:TerminateInstances",
          "ec2:RebootInstances",
          "ec2:StopInstances",
          "ec2:StartInstances",
          # EKS 노드그룹
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:TerminateNodegroupInstances",
          # RDS Failover
          "rds:DescribeDBInstances",
          "rds:RebootDBInstance",
          # ElastiCache Failover
          "elasticache:DescribeReplicationGroups",
          "elasticache:DescribeCacheClusters",
          "elasticache:InterruptClusterAzPower",
          # SSM (CPU 스트레스, POD 삭제)
          "ssm:SendCommand",
          "ssm:ListCommands",
          "ssm:ListCommandInvocations",
          "ssm:GetCommandInvocation",
          "ssm:CancelCommand",
          "ssm:DescribeInstanceInformation",
          # CloudWatch (Stop Condition용)
          "cloudwatch:DescribeAlarms",
          # FIS 로그
          "logs:CreateLogDelivery",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeResourcePolicies"
        ]
        Resource = "*"
      }
    ]
  })
}
