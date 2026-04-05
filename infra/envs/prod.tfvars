# ─── PROD environment ───────────────────────────────────────────────────────
# Estimated cost while running:
#   EKS control plane    : ~$72/month
#   NAT Gateway          : ~$64/month (2 AZs)
#   EC2 ON_DEMAND t3.large: ~$120/month
#   TOTAL                : ~$256/month
#
# Destroy when not in use:
#   terraform destroy -var-file="envs/prod.tfvars"

project_name       = "playground"
environment        = "prod"
aws_region         = "us-east-1"
kubernetes_version = "1.29"

vpc_cidr           = "10.1.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]
private_subnets    = ["10.1.1.0/24", "10.1.2.0/24"]
public_subnets     = ["10.1.101.0/24", "10.1.102.0/24"]

node_groups = {
  general = {
    instance_types = ["t3.large"]
    desired_size   = 2
    min_size       = 2
    max_size       = 5
    disk_size      = 50
    capacity_type  = "ON_DEMAND"
  }
}
