# modules/ecr/main.tf
# modules/ecr/main.tf
#
# 생성 리소스:
#   - aws_ecr_repository      : 컨테이너 이미지 저장소 team3-matnani-api
#                                frontend는 S3+CloudFront 정적 호스팅으로 대체
#   - aws_ecr_lifecycle_policy : 이미지 10개 초과 시 오래된 것부터 자동 삭제
#                                저장 비용 절감

locals {
  common_tags = {
    Team      = var.team
    Project   = var.project
    ManagedBy = "terraform"
  }
}

resource "aws_ecr_repository" "this" {
  for_each = toset(var.repositories)

  # 이름 형식: team3-matnani-api
  name                 = "${var.team}-${var.project}-${var.env}-${each.value}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.team}-${var.project}-${each.value}"
  })
}


resource "aws_ecr_lifecycle_policy" "this" {
  for_each = toset(var.repositories)

  repository = aws_ecr_repository.this[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "최근 이미지 10개만 유지, 초과분 자동 삭제"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}