variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
  default     = "team3-cluster-dev" 
}
variable "env" {
  description = "환경 구분"
  type        = string
  default     = "dev"
}