# 1. 프론트엔드 정적 파일 저장용 S3 버킷
resource "aws_s3_bucket" "frontend" {
  bucket        = "team3-matnani-${var.env}-frontend"
  force_destroy = true # 인프라 일일 셧다운 및 테스트 편의를 위해 임시 허용

  tags = {
    Name = "team3-matnani-${var.env}-frontend"
    Team = "team3"
  }
}

# 2. S3 퍼블릭 액세스 전면 차단
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. CloudFront OAC (Origin Access Control) 생성
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "team3-matnani-${var.env}-oac"
  description                       = "OAC for Matnani Frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewerExceptHostHeader"
}

# 4. CloudFront Distribution 생성
resource "aws_cloudfront_distribution" "this" {

  # 기존 원본: S3 (프론트엔드)
  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.frontend.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  # 이미지 S3 버킷
  origin {
    domain_name              = aws_s3_bucket.image_bucket.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.image_bucket.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.image.id
  }

  # ALB (백엔드)
  origin {
    domain_name = var.alb_dns_name
    origin_id   = "ALB-Backend"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # 이미지 라우팅 (/images/*)
  ordered_cache_behavior {
    path_pattern     = "/images/*"
    target_origin_id = "S3-${aws_s3_bucket.image_bucket.id}"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.image_path_rewrite.arn
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  # 백엔드 API 라우팅 (/api/*)
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    target_origin_id = "ALB-Backend"

    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id

    viewer_protocol_policy = "redirect-to-https"
  }

  # S3 프론트엔드 라우팅
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # SPA (React 등) 라우팅을 위한 403/404 에러 처리 추가
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "team3-matnani-${var.env}-cf"
    team = "team3"
  }
}



# 5. S3 버킷 정책
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.this.arn
          }
        }
      }
    ]
  })
}
# 6. 유저 이미지 업로드용 S3 버킷 생성
resource "aws_s3_bucket" "image_bucket" {
  bucket        = "team3-matnani-${var.env}-images"
  force_destroy = true

  tags = {
    Name = "team3-matnani-${var.env}-images"
    Team = "team3"
  }
}

# 7. S3 퍼블릭 액세스 전면 차단
resource "aws_s3_bucket_public_access_block" "image_bucket_public_access" {
  bucket = aws_s3_bucket.image_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 8. /images/* 경로에서 /images 프리픽스를 제거해 S3 루트 키로 매핑하는 CloudFront Function
resource "aws_cloudfront_function" "image_path_rewrite" {
  name    = "team3-matnani-${var.env}-image-path-rewrite"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = <<-EOT
    function handler(event) {
      var request = event.request;
      request.uri = request.uri.replace(/^\/images\//, '/');
      return request;
    }
  EOT
}

# 이미지 버킷용 OAC
resource "aws_cloudfront_origin_access_control" "image" {
  name                              = "team3-matnani-${var.env}-image-oac"
  description                       = "OAC for Matnani Image Bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 9. 버킷 정책 (CloudFront OAC 경유 읽기만 허용)
resource "aws_s3_bucket_policy" "image_bucket_policy" {
  bucket = aws_s3_bucket.image_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.image_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.this.arn
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.image_bucket_public_access]
}

# 10. CORS 설정 (프리사인드 URL 업로드용)
resource "aws_s3_bucket_cors_configuration" "image_bucket_cors" {
  bucket = aws_s3_bucket.image_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}