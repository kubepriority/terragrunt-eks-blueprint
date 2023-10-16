vpc_cidr = "10.212.0.0/16"

enabled = true

name = "prd"

public_subnets_cidr_blocks = [
  "10.212.60.0/23",
  "10.212.64.0/23",
  "10.212.68.0/23",
]

private_subnets_cidr_blocks = [
  "10.212.4.0/22",
  "10.212.12.0/22",
  "10.212.20.0/22",
]

database_subnets_cidr_blocks = [
  "10.212.28.0/24",
  "10.212.30.0/24",
  "10.212.32.0/24",
]

elasticache_subnets_cidr_blocks = [
  "10.212.36.0/22",
  "10.212.44.0/22",
  "10.212.52.0/22",
]

redshift_subnets_cidr_blocks = [
  "10.212.0.0/24",
  "10.212.2.0/24",
]

image_id = "ami-04a3fea0ceec717e5"

instance_types = "t4g.small"

use_spot_instance = true

key_name = "treinamento-prd"

user_data_write_files = []

user_data_runcmd = []

tags = {
  "Environment" = "Production",
  "Project" = "ProjectName",
  // Adicione mais tags conforme necessário
}

ssm_policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"