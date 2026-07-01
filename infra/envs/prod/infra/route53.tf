# Route 53 Hosted Zone
resource "aws_route53_zone" "this" {
  name = "matnani.store"
}

# ACM 인증서 — KMS 권한 문제로 콘솔에서 수동 발급, ARN 직접 참조
locals {
  acm_certificate_arn = "arn:aws:acm:us-east-1:495599735720:certificate/edcd98fe-0148-4ca1-a71f-999697b93bdd"
}

# matnani.store → CloudFront alias A 레코드
resource "aws_route53_record" "cloudfront" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "matnani.store"
  type    = "A"

  alias {
    name                   = module.cloudfront.distribution_domain_name
    zone_id                = module.cloudfront.distribution_hosted_zone_id
    evaluate_target_health = false
  }
}
