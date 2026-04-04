terraform {
  backend "s3" {
    bucket         = "terraform-aws-pipeline-state"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-aws-pipeline-lock"
  }
}
