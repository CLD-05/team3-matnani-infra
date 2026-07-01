db_instance_class      = "db.t3.large"
create_read_replica    = false
replica_instance_class = "db.t3.large"

redis_node_type          = "cache.t4g.small"
redis_num_nodes          = 2
redis_transit_encryption = false

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
