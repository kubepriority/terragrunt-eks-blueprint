# Generated by Terragrunt. Sig: nIlQXj57tbuaRZEa
data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Environment"
    values = ["prod"]
  }
}

data "terraform_remote_state" "remote" {
  backend = "s3"
  config = {
    bucket         = "vpc-terraform-treinamento-state-prd"
    dynamodb_table = "treinamento-tf-lock-table-prd"
    encrypt        = true
    key            = "vpc/terraform.tfstate"
    region         = "us-east-1"
  }
}

data "terraform_remote_state" "eks_remote" {
  backend = "s3"
  config = {
    bucket         = "vpc-terraform-treinamento-state-prd"
    dynamodb_table = "treinamento-tf-lock-table-prd"
    encrypt        = true
    key            = "eks-blueprint-prd/terraform.tfstate"
    region         = "us-east-1"
  }
}
