# ─── DEV environment ────────────────────────────────────────────────────────
# Estimated cost while running:
#   EKS control plane : ~$72/month
#   NAT Gateway       : ~$32/month
#   EC2 SPOT t3.medium: ~$20/month
#   TOTAL             : ~$124/month
#
# Destroy when not in use:
#   terraform destroy -var-file="envs/dev.tfvars"

project_name       = "playground"
environment        = "dev"
aws_region         = "us-east-1"
kubernetes_version = "1.29"

vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]
private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]

node_groups = {
  general = {
    instance_types = ["t3.medium"]
    desired_size   = 2
    min_size       = 1
    max_size       = 3
    disk_size      = 20
    capacity_type  = "SPOT"
  }
}
