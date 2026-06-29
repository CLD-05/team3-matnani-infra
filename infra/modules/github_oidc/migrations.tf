# count 도입 전 Dev state의 공용 GitHub Actions Role 주소를 유지합니다.
moved {
  from = aws_iam_role.gha_dev
  to   = aws_iam_role.gha_dev[0]
}

moved {
  from = aws_iam_role.gha_prod
  to   = aws_iam_role.gha_prod[0]
}
