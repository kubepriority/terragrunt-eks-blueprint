locals {
  common_vars = {
    aws_region       = "us-east-1"
    s3_bucket        = "vpc-terraform-treinamento-state-prd"
    dynamodb_table   = "treinamento-tf-lock-table-prd"
  }
}

generate "version" {
  path      = "version.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.47"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }
}
EOF
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
