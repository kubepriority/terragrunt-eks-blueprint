locals {
  common_vars = {
    aws_region       = "us-east-1"
    s3_bucket        = "vpc-terraform-treinamento-state-prd"
    dynamodb_table   = "treinamento-tf-lock-table-prd"
    cluster_version  = "1.26"
  }
}