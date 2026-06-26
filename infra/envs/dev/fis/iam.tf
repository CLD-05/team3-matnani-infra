# infra/envs/dev/fis/iam.tf
#
# FIS IAM Role/Policy는 TeamRuntimeBoundary 제약으로 GHA에서 생성/수정 불가
# → CLI로 사전 생성 후 data source로 참조
#
# 사전 생성 명령 (팀 계정으로 1회 실행):
#
# 1) Role 생성
#   aws iam create-role \
#     --role-name team3-matnani-dev-fis-role \
#     --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"fis.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
#     --permissions-boundary arn:aws:iam::495599735720:policy/TeamRuntimeBoundary
#
# 2) Inline Policy 연결
#   aws iam put-role-policy \
#     --role-name team3-matnani-dev-fis-role \
#     --policy-name team3-matnani-dev-fis-policy \
#     --policy-document file://fis-policy.json
#
# fis-policy.json 내용:
# {
#   "Version": "2012-10-17",
#   "Statement": [{
#     "Effect": "Allow",
#     "Action": [
#       "ec2:DescribeInstances","ec2:TerminateInstances","ec2:RebootInstances","ec2:StopInstances","ec2:StartInstances",
#       "eks:DescribeNodegroup","eks:ListNodegroups","eks:TerminateNodegroupInstances",
#       "rds:DescribeDBInstances","rds:RebootDBInstance",
#       "elasticache:DescribeReplicationGroups","elasticache:DescribeCacheClusters","elasticache:InterruptClusterAzPower",
#       "ssm:SendCommand","ssm:ListCommands","ssm:ListCommandInvocations","ssm:GetCommandInvocation","ssm:CancelCommand","ssm:DescribeInstanceInformation",
#       "cloudwatch:DescribeAlarms",
#       "logs:CreateLogDelivery","logs:PutLogEvents","logs:DescribeLogGroups","logs:DescribeResourcePolicies"
#     ],
#     "Resource": "*"
#   }]
# }

data "aws_iam_role" "fis" {
  name = "${local.prefix}-fis-role"
}
