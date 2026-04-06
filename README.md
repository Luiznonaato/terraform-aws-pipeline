# terraform-aws-pipeline

> **Cloud Infra Challenge — Project 4/100**

Terraform project with a fully automated GitHub Actions CI/CD pipeline for provisioning an EKS cluster on AWS. Infrastructure code is adapted from [eks-cluster](https://github.com/Luiznonaato/eks-cluster).

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          AWS (us-east-1)                        │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  VPC  10.0.0.0/16                                        │   │
│  │                                                          │   │
│  │  ┌─────────────────┐    ┌─────────────────┐             │   │
│  │  │  Public Subnet  │    │  Public Subnet  │             │   │
│  │  │  us-east-1a     │    │  us-east-1b     │             │   │
│  │  │  (NAT Gateway)  │    │  (Load Balancer)│             │   │
│  │  └────────┬────────┘    └─────────────────┘             │   │
│  │           │                                              │   │
│  │  ┌────────▼────────┐    ┌─────────────────┐             │   │
│  │  │  Private Subnet │    │  Private Subnet │             │   │
│  │  │  us-east-1a     │    │  us-east-1b     │             │   │
│  │  │  (EKS Nodes)    │    │  (EKS Nodes)    │             │   │
│  │  └─────────────────┘    └─────────────────┘             │   │
│  │                                                          │   │
│  │  ┌────────────────────────────────────────────────────┐  │   │
│  │  │             EKS Control Plane                      │  │   │
│  │  │  Kubernetes 1.29  │  Logs: api, audit              │  │   │
│  │  └────────────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  S3 Bucket: terraform-aws-pipeline-state  (remote state)        │
│  DynamoDB:  terraform-aws-pipeline-lock   (state locking)       │
└─────────────────────────────────────────────────────────────────┘
```

### Modules

| Module | Description |
|--------|-------------|
| `vpc`  | VPC, public/private subnets, Internet Gateway, NAT Gateway, route tables |
| `iam`  | IAM roles for EKS control plane and worker nodes |
| `eks`  | EKS cluster and managed node groups (SPOT instances) |

---

## CI/CD Pipeline

```
Developer
   │
   ├─── git push (feature branch)
   │         │
   │         ▼
   │    Pull Request → main
   │         │
   │         ▼
   │    [terraform-plan.yml]
   │    ├── terraform init
   │    ├── terraform validate
   │    ├── terraform fmt -check
   │    └── terraform plan → posts result as PR comment
   │
   ├─── PR approved → merge to main
   │         │
   │         ▼
   │    [terraform-apply.yml]
   │    ├── terraform init
   │    ├── terraform validate
   │    └── terraform apply -auto-approve
   │
   └─── Infrastructure provisioned ✅
```

### Workflow triggers

| Workflow | Trigger | Action |
|----------|---------|--------|
| `terraform-plan.yml` | Pull Request to `main` | Runs `terraform plan`, posts output as PR comment |
| `terraform-apply.yml` | Push/merge to `main` | Runs `terraform apply -auto-approve` |
| `terraform-destroy.yml` | Manual dispatch only | Runs `terraform destroy` — requires typing "DESTROY" to confirm |

The plan and apply workflows only run when files inside `infra/` change.

---

## Project Structure

```
terraform-aws-pipeline/
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml
│       ├── terraform-apply.yml
│       └── terraform-destroy.yml
├── infra/
│   ├── main.tf          # Provider, root module calls
│   ├── variables.tf     # Input variables
│   ├── outputs.tf       # Output values
│   ├── backend.tf       # S3 remote state + DynamoDB locking
│   └── modules/
│       ├── vpc/         # VPC, subnets, NAT, routes
│       ├── iam/         # IAM roles for EKS
│       └── eks/         # EKS cluster + node groups
├── .gitignore
└── README.md
```

---

## Remote State

Remote state is stored in S3 with DynamoDB locking and encryption:

```hcl
backend "s3" {
  bucket         = "terraform-aws-pipeline-state"
  key            = "eks/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-aws-pipeline-lock"
}
```

> **Before running the pipeline**, create the S3 bucket and DynamoDB table:
>
> ```bash
> # S3 bucket with versioning and encryption
> aws s3api create-bucket --bucket terraform-aws-pipeline-state --region us-east-1
> aws s3api put-bucket-versioning \
>   --bucket terraform-aws-pipeline-state \
>   --versioning-configuration Status=Enabled
> aws s3api put-bucket-encryption \
>   --bucket terraform-aws-pipeline-state \
>   --server-side-encryption-configuration \
>   '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
>
> # DynamoDB table for state locking
> aws dynamodb create-table \
>   --table-name terraform-aws-pipeline-lock \
>   --attribute-definitions AttributeName=LockID,AttributeType=S \
>   --key-schema AttributeName=LockID,KeyType=HASH \
>   --billing-mode PAY_PER_REQUEST \
>   --region us-east-1
> ```

---

## Required GitHub Secrets

Go to **Settings → Secrets and variables → Actions** and add:

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM user secret key |

The IAM user needs the following permissions: `AmazonEKSFullAccess`, `AmazonVPCFullAccess`, `IAMFullAccess`, `AmazonS3FullAccess`, `AmazonDynamoDBFullAccess`.

---

## Estimated Cost

| Resource | Monthly Cost |
|----------|-------------|
| EKS Control Plane | ~$72 |
| NAT Gateway (1) | ~$32 |
| EC2 SPOT t3.medium x2 | ~$20 |
| **Total** | **~$124/month** |

> Destroy when not in use: `terraform destroy -var="environment=dev"`

---

## Related Projects

- [eks-cluster](https://github.com/Luiznonaato/eks-cluster) — original EKS infrastructure (project 1/100)
