# Incorpora o conteúdo do arquivo 'locals.hcl' que está no mesmo diretório ou em um diretório pai
locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("locals.hcl")).locals.common_vars
}

# prod/vpc/terragrunt.hcl
include {
  path = find_in_parent_folders()
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

data "aws_eks_addon_version" "latest" {
  for_each = toset(["vpc-cni"])

  addon_name         = each.value
  kubernetes_version = module.eks.cluster_version
  most_recent        = true
}

data "aws_ssm_parameter" "eks_optimized_ami" {
  name = "/aws/service/eks/optimized-ami/${local.common_vars.cluster_version}/amazon-linux-2/recommended/image_id"
}
EOF
}

generate "variables" {
  path      = "terraform.auto.tfvars"
  if_exists = "overwrite"
  contents  = <<EOF
aws_region            = "${local.common_vars.aws_region}"
cluster_version       = "${local.common_vars.cluster_version}"
cluster_name          = "${local.common_vars.cluster_name}"
certificate_arn       = "${local.common_vars.certificate_arn}"
start_time_scale_up   = "${local.common_vars.start_time_scale_up}"
start_time_scale_down = "${local.common_vars.start_time_scale_down}"
EOF
}