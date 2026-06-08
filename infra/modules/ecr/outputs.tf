# modules/ecr/outputs.tf
#
# Outputs:
# - repository_urls : GitHub Actions CI에서 이미지 push 시 참조
#                       docker push {url}:{tag}
# - repository_arns : github_oidc 모듈 gha-ci-role 정책에서 ECR ARN 지정시 참조
# - repository_names : ECR 레포지토리 이름

output "repository_urls" {
  description = "ECR 레포지토리 URL 맵"
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_arns" {
  description = "ECR 레포지토리 ARN 맵"
  value       = { for k, v in aws_ecr_repository.this : k => v.arn }
}

output "repository_names" {
  description = "ECR 레포지토리 이름"
  value = {
    for key, repo in aws_ecr_repository.this : key => repo.name
  }
}