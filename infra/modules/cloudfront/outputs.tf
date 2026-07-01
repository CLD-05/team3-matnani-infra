output "cloudfront_domain_name" {
  description = "프론트엔드 접속용 CloudFront 도메인 주소"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "s3_bucket_name" {
  description = "정적 파일 업로드용 S3 버킷 이름"
  value       = aws_s3_bucket.frontend.id
}

output "distribution_arn" {
  description = "CloudFront 배포의 전체 ARN (GitHub OIDC 및 모니터링 연동용)"
  value       = aws_cloudfront_distribution.this.arn
}

output "frontend_bucket_arn" {
  description = "프론트엔드 정적 파일이 저장되는 S3 버킷의 ARN"
  value       = aws_s3_bucket.frontend.arn
}

output "distribution_id" {
  description = "CloudFront 배포 ID (필요 시 캐시 무효화 등에 사용)"
  value       = aws_cloudfront_distribution.this.id
}

output "image_bucket_name" {
  description = "이미지 업로드용 S3 버킷 이름"
  value       = aws_s3_bucket.image_bucket.id
}

output "image_bucket_arn" {
  description = "이미지 업로드용 S3 버킷 ARN"
  value       = aws_s3_bucket.image_bucket.arn
}

output "distribution_hosted_zone_id" {
  description = "CloudFront 배포의 hosted zone ID (Route 53 alias 레코드용)"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "distribution_domain_name" {
  description = "CloudFront 배포 도메인 (Route 53 alias 레코드 타겟용)"
  value       = aws_cloudfront_distribution.this.domain_name
}
