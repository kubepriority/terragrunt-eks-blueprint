locals {
  common_vars = {
    aws_region       = "us-east-1"
    s3_bucket        = "vpc-terraform-treinamento-state-lab"
    dynamodb_table   = "treinamento-tf-lock-table-lab"
    cluster_version  = "1.26"
  }
}