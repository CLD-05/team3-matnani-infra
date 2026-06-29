# 선택적 설치로 전환된 기존 Dev ExternalDNS의 state 주소를 유지합니다.
moved {
  from = helm_release.external_dns
  to   = helm_release.external_dns[0]
}
