# infra/envs/dev/fis/experiments.tf
#
# 카오스 엔지니어링 실험 5종
# 실행: AWS 콘솔 → FIS → Experiment Templates → Start Experiment
#
# ⚠️  실행 전 확인 사항
#   - node_desired > 0 (EKS 노드 실행 중)
#   - RDS Multi-AZ 활성화 (create_read_replica = false여도 Multi-AZ 별도 설정)
#   - 부하테스트와 중복 실행 금지

# ─────────────────────────────────────────
# 1. EKS 노드 종료
#    워커 노드 50% 강제 종료 → Cluster Autoscaler 자동 복구 확인
# ─────────────────────────────────────────
resource "aws_fis_experiment_template" "eks_node_terminate" {
  description = "[카오스] EKS 워커 노드 50% 강제 종료 → CA 자동 복구 확인"
  role_arn    = data.aws_iam_role.fis.arn

  stop_condition {
    source = "none"
  }

  action {
    name      = "terminate-eks-nodes"
    action_id = "aws:eks:terminate-nodegroup-instances"

    parameter {
      key   = "instanceTerminationPercentage"
      value = "50"
    }

    target {
      key   = "Nodegroups"
      value = "eks-nodegroup"
    }
  }

  target {
    name           = "eks-nodegroup"
    resource_type  = "aws:eks:nodegroup"
    selection_mode = "ALL"
    resource_arns  = [data.aws_eks_node_group.main.arn]
  }

  tags = {
    Name        = "${local.prefix}-eks-node-terminate"
    Scenario    = "eks-node-terminate"
    Environment = var.env
  }
}

# ─────────────────────────────────────────
# 2. RDS Failover
#    RDS Multi-AZ 장애 조치 → 스탠바이 자동 승격 및 애플리케이션 재연결 확인
# ─────────────────────────────────────────
resource "aws_fis_experiment_template" "rds_failover" {
  description = "[카오스] RDS Multi-AZ 장애 조치 → 스탠바이 승격 및 재연결 확인"
  role_arn    = data.aws_iam_role.fis.arn

  stop_condition {
    source = "none"
  }

  action {
    name      = "rds-reboot-failover"
    action_id = "aws:rds:reboot-db-instances"

    parameter {
      key   = "forceFailover"
      value = "true"
    }

    target {
      key   = "DBInstances"
      value = "rds-instance"
    }
  }

  target {
    name           = "rds-instance"
    resource_type  = "aws:rds:db"
    selection_mode = "ALL"
    resource_arns  = [data.aws_db_instance.main.db_instance_arn]
  }

  tags = {
    Name        = "${local.prefix}-rds-failover"
    Scenario    = "rds-failover"
    Environment = var.env
  }
}

# ─────────────────────────────────────────
# 3. CPU 스트레스
#    EKS 워커 노드 전체에 60초간 CPU 100% 부하 주입
#    → HPA/CA 스케일 반응 및 Grafana 알람 확인
# ─────────────────────────────────────────
resource "aws_fis_experiment_template" "cpu_stress" {
  description = "[카오스] EKS 노드 CPU 100% 60초 부하 → HPA/CA 반응 및 알람 확인"
  role_arn    = data.aws_iam_role.fis.arn

  stop_condition {
    source = "none"
  }

  action {
    name      = "cpu-stress"
    action_id = "aws:ssm:send-command"

    parameter {
      key   = "documentArn"
      value = "arn:aws:ssm:ap-northeast-2::document/AWSFIS-Run-CPU-Stress"
    }

    parameter {
      key = "documentParameters"
      value = jsonencode({
        DurationSeconds     = "60"
        CPU                 = "0"
        InstallDependencies = "True"
      })
    }

    parameter {
      key   = "duration"
      value = "PT2M"
    }

    target {
      key   = "Instances"
      value = "eks-nodes"
    }
  }

  target {
    name           = "eks-nodes"
    resource_type  = "aws:ec2:instance"
    selection_mode = "ALL"

    resource_tag {
      key   = "eks:cluster-name"
      value = data.terraform_remote_state.infra.outputs.cluster_name
    }
  }

  tags = {
    Name        = "${local.prefix}-cpu-stress"
    Scenario    = "cpu-stress"
    Environment = var.env
  }
}

# ─────────────────────────────────────────
# 5. POD 강제 종료
#    bastion SSM을 통해 matnani 네임스페이스 POD 전체 삭제
#    → Deployment 자동 재시작 및 서비스 복구 확인
#    전제: bastion에 kubectl 설치 + kubeconfig 설정 (/root/.kube/config)
# ─────────────────────────────────────────
resource "aws_fis_experiment_template" "pod_delete" {
  description = "[카오스] matnani 네임스페이스 POD 전체 삭제 → Deployment 자동 재시작 확인"
  role_arn    = data.aws_iam_role.fis.arn

  stop_condition {
    source = "none"
  }

  action {
    name      = "pod-delete-via-kubectl"
    action_id = "aws:ssm:send-command"

    parameter {
      key   = "documentArn"
      value = "arn:aws:ssm:ap-northeast-2::document/AWS-RunShellScript"
    }

    parameter {
      key = "documentParameters"
      value = jsonencode({
        commands = [
          "kubectl delete pod --all -n matnani --grace-period=0 --force"
        ]
      })
    }

    parameter {
      key   = "duration"
      value = "PT2M"
    }

    target {
      key   = "Instances"
      value = "bastion"
    }
  }

  target {
    name           = "bastion"
    resource_type  = "aws:ec2:instance"
    selection_mode = "ALL"

    resource_tag {
      key   = "Name"
      value = "${local.prefix}-bastion"
    }
  }

  tags = {
    Name        = "${local.prefix}-pod-delete"
    Scenario    = "pod-delete"
    Environment = var.env
  }
}
