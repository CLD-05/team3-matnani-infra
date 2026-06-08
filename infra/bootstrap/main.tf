# bootstrap/main.tf

# 생성 리소스:
#   - aws_s3_bucket                                      : dev/prod 공용 state 버킷
#   - aws_s3_bucket_ownership_controls                   : ACL 비활성화
#   - aws_s3_bucket_public_access_block                  : 퍼블릭 접근 차단
#   - aws_s3_bucket_versioning                           : state 버전 관리
#   - aws_s3_bucket_server_side_encryption_configuration : AES256 암호화
#   - aws_iam_openid_connect_provider

locals {
  team        = "team3"
  project     = "matnani"
  region      = "ap-northeast-2"
  bucket_name = "team3-matnani-tfstate"

  common_tags = {
    Team        = local.team
    Environment = "shared"
    Project     = local.project
    Owner       = local.team
  }
}

# 현재 AWS 계정 정보 확인
data "aws_caller_identity" "current" {}


# backend key를 다르게 해서 state를 분리
/* team3/dev/infra/terraform.tfstate
team3/dev/platform-addons/terraform.tfstate
team3/prod/infra/terraform.tfstate
team3/prod/platform-addons/terraform.tfstate */
resource "aws_s3_bucket" "tfstate" {
  bucket        = local.bucket_name
  force_destroy = false

  tags = merge(local.common_tags, {
    Name = local.bucket_name
  })
}


# ACL 비활성화
resource "aws_s3_bucket_ownership_controls" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}


resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  depends_on = [aws_s3_bucket_ownership_controls.tfstate]

  # 퍼블릭 접근 전부 차단
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


# GitHub Actions OIDC Provider
# 계정당 1개만 존재 가능 → bootstrap에서 한 번만 생성
# 다른 팀이 이미 생성한 경우 아래 import 블록이 기존 리소스를 가져옴
import {
  to = aws_iam_openid_connect_provider.github
  id = "arn:aws:iam::495599735720:oidc-provider/token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = merge(local.common_tags, {
    Name = "github-oidc-provider"
  })
}