#locals.hcl
locals {
  common_vars = {
    aws_region            = "us-east-1"
    s3_bucket             = "vpc-terraform-967383985264-state"
    dynamodb_table        = "967383985264-tf-lock-table"
    cluster_version       = "1.27"
    cluster_name          = "eks-967383985264-prd"
    certificate_arn       = "arn:aws:acm:us-east-1:219469607196:certificate/2e661337-1745-485a-9c2e-fa4343f9bd9e"
    start_time_scale_up   = "2024-02-20T08:00:00Z"
    start_time_scale_down = "2024-02-20T16:00:00Z"
    enable_alb_ingress    = "true"
  }
}