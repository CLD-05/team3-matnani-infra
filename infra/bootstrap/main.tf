# bootstrap/main.tf

# 생성 리소스:
#   - aws_s3_bucket                                      : dev/prod 공용 state 버킷
#   - aws_s3_bucket_ownership_controls                   : ACL 비활성화
#   - aws_s3_bucket_public_access_block                  : 퍼블릭 접근 차단
#   - aws_s3_bucket_versioning                           : state 버전 관리
#   - aws_s3_bucket_server_side_encryption_configuration : AES256 암호화


# 실행 후:
#   - envs/dev/infra/backend.tf, envs/dev/platform-addons/backend.tf
#     envs/prod/infra/backend.tf, envs/prod/platform-addons/backend.tf
#     에서 bucket = "team3-matnani-tfstate" 로 참조

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
# team3/dev/infra/terraform.tfstate
# team3/dev/platform-addons/terraform.tfstate
# team3/prod/infra/terraform.tfstate
# team3/prod/platform-addons/terraform.tfstate
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