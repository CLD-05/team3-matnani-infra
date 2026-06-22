node_desired = 3
node_min     = 3
node_max     = 4

db_instance_class   = "db.t4g.micro"
create_read_replica = false

redis_node_type = "cache.t4g.micro"
redis_num_nodes = 1

github_org = "CLD-05"
app_repo   = "team3-matnani-app"
infra_repo = "team3-matnani-infra"

team_member_user_arns = {
  sanghyuk = "arn:aws:iam::495599735720:user/team3-lsh"
  yueun    = "arn:aws:iam::495599735720:user/team3-lye"
  leeho    = "arn:aws:iam::495599735720:user/team3-lh"
  mingyu   = "arn:aws:iam::495599735720:user/team3-cmg"
  wonjun   = "arn:aws:iam::495599735720:user/team3-swj"
  wonho    = "arn:aws:iam::495599735720:user/team3-kwh"
}

# Amazon Q Developer in chat applications
slack_workspace_id = "T0B9G4MP3BL"
slack_channel_id   = "C0B9KP6RDGU"
chatbot_role_arn   = "arn:aws:iam::495599735720:role/team3-matnani-dev-chatbot-role"

# 기존 infra monitoring 모듈에서 사용하던 Prometheus 스토리지 설정입니다.
# 현재 kube-prometheus-stack은 platform-addons에서 관리하므로 비활성화합니다.
# prometheus_storage_class = "gp2"
# prometheus_storage_size  = "10Gi"

alb_dns_name = "team3-matnani-dev-alb-1335037742.ap-northeast-2.elb.amazonaws.com"
