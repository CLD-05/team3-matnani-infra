output "cloudfront_domain_name" {
  description = "프론트엔드 접속용 CloudFront 도메인 주소"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "s3_bucket_name" {
  description = "정적 파일 업로드용 S3 버킷 이름"
  value       = aws_s3_bucket.frontend.id
}