# bootstrap/outputs.tf

# Outputs
# - tfstate_bucket_name : 각 envs/*/backend.tf의 bucket 값으로 사용
# - tfstate_bucket_arn : GitHub Actions OIDC role이나 IAM policy에서 state bucket 접근 권한 줄 때 사용
# - backend_keys : 각 root module이 사용할 state key 경로 안내용
# - backend_region : ap-northeast-2

output "tfstate_bucket_name" {
  description = "S3 state 버킷 이름 — envs/*/backend.tf에서 참조"
  value       = aws_s3_bucket.tfstate.bucket
}

output "tfstate_bucket_arn" {
  description = " GitHub Actions OIDC Role 권한 정책 작성"
  value       = aws_s3_bucket.tfstate.arn
}

output "backend_region" {
  # backend.tf의 region과 동일해야 함.
  description = "S3 backend AWS region"
  value       = local.region
}

output "backend_keys" {
  description = "하나의 S3 버킷 안에서 dev/prod와 infra/platform-addons 분리"
  value = {
    dev_infra            = "team3/dev/infra/terraform.tfstate"
    dev_platform_addons  = "team3/dev/platform-addons/terraform.tfstate"
    prod_infra           = "team3/prod/infra/terraform.tfstate"
    prod_platform_addons = "team3/prod/platform-addons/terraform.tfstate"
  }
}

output "account_id" {
  description = "AWS 계정 ID 확인용"
  value       = data.aws_caller_identity.current.account_id
}

output "github_oidc_provider_arn" {
  description = "github_oidc 모듈에서 data source로 참조"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_oidc_provider_url" {
  description = "IRSA 신뢰 정책 Condition 작성 시 참조"
  value       = aws_iam_openid_connect_provider.github.url
}