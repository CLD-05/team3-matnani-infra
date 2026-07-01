# Route 53 Hosted Zone
resource "aws_route53_zone" "this" {
  name = "matnani.store"
}

# ACM 인증서 — CloudFront는 반드시 us-east-1 리전 인증서 필요
resource "aws_acm_certificate" "cloudfront" {
  provider          = aws.us_east_1
  domain_name       = "matnani.store"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# ACM DNS 검증용 Route 53 레코드
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = aws_route53_zone.this.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# 인증서 검증 완료 대기
resource "aws_acm_certificate_validation" "cloudfront" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
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
