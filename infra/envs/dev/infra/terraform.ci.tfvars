node_desired = 2
node_min     = 0
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

prometheus_storage_class = "gp2"
prometheus_storage_size  = "10Gi"
slack_workspace_id       = "T0000000000"
slack_channel_id         = "C0000000000"
alb_dns_name = "team3-matnani-dev-alb-1335037742.ap-northeast-2.elb.amazonaws.com"
