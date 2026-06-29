# modules/eks/variables.tf

variable "team" {
  description = "팀 식별자"
  type        = string
}

variable "project" {
  description = "프로젝트명"
  type        = string
}

variable "env" {
  description = "배포 환경 (dev/prod)"
  type        = string
}

variable "permissions_boundary" {
  description = "IAM Role 권한 경계 ARN — team3-* role 생성 시 필수"
  type        = string
  default     = "arn:aws:iam::495599735720:policy/TeamRuntimeBoundary"
}



# 네트워크
variable "vpc_id" {
  description = "network 모듈 output — Security Group 생성용"
  type        = string
}

variable "private_subnet_ids" {
  description = "network 모듈 output — 노드그룹 배치할 프라이빗 서브넷 ID 목록"
  type        = list(string)
}

variable "network_ready" {
  description = "EKS 노드 생성 전에 준비되어야 하는 public internet route ID"
  type        = string
}



# EKS 클러스터 설정
variable "endpoint_public_access" {
  description = "EKS API 서버 퍼블릭 접근 허용 여부 (dev: true / prod: false)"
  type        = bool
  default     = true
}


# 노드그룹 설정
variable "node_desired_size" {
  description = "dev: 3 / prod: 4"
  type        = number
}

variable "node_min_size" {
  description = "dev: 3 / prod: 4"
  type        = number
}

variable "node_max_size" {
  description = "dev: 4 / prod: 8"
  type        = number
}

variable "node_instance_types" {
  description = "dev: [t3.medium] / prod: [m6i.large]"
  type        = list(string)
  default     = ["t3.medium"]
}



# EKS Add-on 버전 고정 (>= 금지)
variable "vpc_cni_version" {
  description = "vpc-cni add-on 버전"
  type        = string
}

variable "coredns_version" {
  description = "coredns add-on 버전"
  type        = string
}

variable "kube_proxy_version" {
  description = "kube-proxy add-on 버전"
  type        = string
}

variable "ebs_csi_version" {
  description = "aws-ebs-csi-driver add-on 버전"
  type        = string
}

variable "ebs_csi_role_arn" {
  description = "EBS CSI IRSA Role ARN — ebs-csi-controller-sa에 연결 (platform-addons 적용 후 입력)"
  type        = string
  default     = ""
}

variable "pod_identity_agent_version" {
  description = "eks-pod-identity-agent add-on 버전"
  type        = string
}


# 팀원 EKS 접근
variable "team_member_user_arns" {
  description = "EKS Access Entry에 등록할 팀원 IAM 유저 ARN 맵"
  type        = map(string)
  default     = {}
  # 예시:
  # {
  #   yueun    = "arn:aws:iam::495599735720:user/team3-yueun"
  # }
}

variable "gha_role_arn" {
  description = "GitHub Actions dev role ARN — CI에서 kubectl/terraform 사용 시 EKS 접근"
  type        = string
  default     = ""
}

variable "enable_gha_access" {
  description = "GHA role EKS access entry 생성 여부 — computed ARN을 count에 쓸 수 없어서 별도 플래그로 분리"
  type        = bool
  default     = false
}
