locals {
  common_vars = {
    aws_region       = "us-east-1"
    s3_bucket        = "vpc-terraform-treinamento-state-prd"
    dynamodb_table   = "treinamento-tf-lock-table-prd"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.common_vars.aws_region}"
  default_tags {
    tags = {
      Managed_by  = "Terraform"
      Environment = "Prd"
      map-migrated= "d-server-02dzarjfi0ibj1"
    }
  }
}
EOF
}

generate "data" {
  path      = "data.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Environment"
    values = ["prod"]
  }
}

data "terraform_remote_state" "remote" {
  backend = "s3"
  config = {
    bucket         = "${local.common_vars.s3_bucket}"
    dynamodb_table = "${local.common_vars.dynamodb_table}"
    encrypt        = true
    key            = "vpc/terraform.tfstate"
    region         = "${local.common_vars.aws_region}"
  }
}
EOF
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    key = "${path_relative_to_include()}/terraform.tfstate"
    encrypt        = true
    bucket         = "${local.common_vars.s3_bucket}"
    region         = "${local.common_vars.aws_region}"
    dynamodb_table = "${local.common_vars.dynamodb_table}"
  }
}
