## Modulo VPC

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  #version = "~> 3.0"

  name = "vpc-treinamento"
  cidr = var.vpc_cidr

  azs                 = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets     = var.private_subnets_cidr_blocks
  public_subnets      = var.public_subnets_cidr_blocks
  database_subnets    = var.database_subnets_cidr_blocks
  #elasticache_subnets = var.elasticache_subnets_cidr_blocks
  #redshift_subnets    = var.redshift_subnets_cidr_blocks

  create_database_subnet_route_table    = true
  create_database_subnet_group          = true
  #create_database_nat_gateway_route     = false
  #create_elasticache_subnet_route_table = true
  #create_redshift_subnet_route_table    = true

  enable_ipv6 = false
 
  private_subnet_names     = ["Subnet-Private-EKS-AZ-1A", "Subnet-Private-EKS-AZ-1B", "Subnet-Private-EKS-AZ-1C"]
  public_subnet_names      = ["Subnet-Public-AZ-1A", "Subnet-Public-AZ-1B", "Subnet-Public-AZ-1C"]
  database_subnet_names    = ["Subnet-Private-RDS-AZ-1A", "Subnet-Private-RDS-AZ-1B", "Subnet-Private-RDS-AZ-1C"]
  #elasticache_subnet_names = ["Subnet-Private-SF-AZ-1A", "Subnet-Private-SF-AZ-1B", "Subnet-Private-SF-AZ-1C"]
  #redshift_subnet_names    = ["Subnet-Private-VPC-Hub-1A", "Subnet-Private-VPC-Hub-1B"]

  private_subnet_tags = {
    Type = "Private"
    "kubernetes.io/cluster/eks-treinamento-prd"    = "shared"
    "kubernetes.io/role/internal-elb"              = "1"
  }
  public_subnet_tags = {
    Type = "Public"
    "kubernetes.io/cluster/eks-treinamento-prd"    = "shared"
    "kubernetes.io/role/elb"                       = "1"
  }

  #elasticache_route_table_tags = {
  #  Name = "vpc-stf-private-SF"
  #}

  #redshift_route_table_tags = {
  #  Name = "vpc-stf-private-HUB"
  #}

  enable_dns_hostnames   = true
  enable_vpn_gateway     = true
  enable_nat_gateway     = false
  single_nat_gateway     = false
  one_nat_gateway_per_az = false
  create_egress_only_igw = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  tags = {
    Terraform = "true"
    Environment = "prod"
  }
  
}

################################################################################
# Transit Gateway Module
################################################################################

#module "tgw" {
#  source  = "terraform-aws-modules/transit-gateway/aws"
#  version = "~> 2.0"
#
#  name        = "tgw-prd-01"
#  description = "PRD 1 TGW shared with several other AWS accounts"
#
#  enable_auto_accept_shared_attachments = true
#
#  vpc_attachments = {
#    vpc = {
#      vpc_id       = module.vpc.vpc_id
#      subnet_ids   = module.vpc.private_subnets
#      dns_support  = true
#      ipv6_support = false
#
#      transit_gateway_default_route_table_association = false
#      transit_gateway_default_route_table_propagation = false
#
#      tgw_routes = [
#        {
#          destination_cidr_block = "10.200.0.0/16"
#        },
#        {
#          destination_cidr_block = "10.205.0.0/22"
#        },
#        {
#          destination_cidr_block = "10.112.0.0/16"
#        }
#      ]
#    }
#  }
#
#  ram_allow_external_principals = true
#  ram_principals = [307990089504]
#
#  tags = {
#    Purpose = "tgw-to-vpn-prd-01"
#  }
#}


## Key Pair

resource "aws_key_pair" "nat_key_name" {
  key_name   = var.key_name
  public_key = "${file("./id_rsa.pub")}"
}


#NAT Instance Zone 1a = zone1a

## Security Groups Roles

resource "aws_security_group" "zone1a" {
  name_prefix = "${var.name}-1a"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for NAT instance ${var.name}"
  tags        = local.common_tags_1a
}

resource "aws_security_group_rule" "egress-zone1a" {
  security_group_id = aws_security_group.zone1a.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
}

resource "aws_security_group_rule" "ingress_any-zone1a" {
  description       = "Subnet-Private-EKS-AZ-1A"
  security_group_id = aws_security_group.zone1a.id
  type              = "ingress"
  cidr_blocks       = slice(var.private_subnets_cidr_blocks, 0, 1)
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
}

resource "aws_security_group_rule" "ingress_sf-zone1a" {
  description       = "Subnet-Private-SF-AZ-1A"
  security_group_id = aws_security_group.zone1a.id
  type              = "ingress"
  cidr_blocks       = slice(var.elasticache_subnets_cidr_blocks, 0, 1)
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
}

resource "aws_security_group_rule" "ingress_HUB-zone1a" {
  description       = "Subnet-Private-VPC-Hub-1A"
  security_group_id = aws_security_group.zone1a.id
  type              = "ingress"
  cidr_blocks       = slice(var.redshift_subnets_cidr_blocks, 0, 1)
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
}

## EIP Public

resource "aws_network_interface" "zone1a" {
  source_dest_check = false 
  subnet_id         = module.vpc.public_subnets[0]
  security_groups   = [aws_security_group.zone1a.id]

  tags = merge(var.tags, { "Name" = "${var.name}-1a" })
}

resource "aws_eip" "eip-zone1a" {
  public_ipv4_pool = "amazon"
  vpc = true
  network_interface = "${aws_network_interface.zone1a.id}"

  tags = merge(var.tags, { "Name" = "${var.name}-1a" })
}

## Nat_Instance

resource "aws_iam_instance_profile" "zone1a" {
  name_prefix = "${var.name}-1a"
  role        = aws_iam_role.zone1a.name
}

resource "aws_iam_role" "zone1a" {
  name_prefix        = "${var.name}-1a"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "ssm-zone1a" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.zone1a.name
}

resource "aws_iam_role_policy" "eni-zone1a" {
  role        = aws_iam_role.zone1a.name
  name_prefix = "${var.name}-1a"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AttachNetworkInterface",
                "ec2:ModifyInstanceAttribute"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}


resource "aws_launch_template" "zone1a" {
  name_prefix          = "${var.name}-1a"
  image_id             = var.image_id
  #key_name             = var.key_name
  instance_type        = var.instance_types
  
  iam_instance_profile {
    arn = aws_iam_instance_profile.zone1a.arn
  }

  network_interfaces {
    device_index = 0
    network_interface_id = "${aws_network_interface.zone1a.id}"
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 10
      volume_type = "gp3"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.common_tags_1a
  }

  user_data = base64encode(join("\n", [
    "#cloud-config",
    yamlencode({
      # https://cloudinit.readthedocs.io/en/latest/topics/modules.html
      write_files : concat([
        {
          path : "/opt/nat/runonce.sh",
          content : templatefile("${path.module}/runonce.sh", { eni_id = aws_network_interface.zone1a.id }),
          permissions : "0755",
        },
        {
          path : "/opt/nat/snat.sh",
          content : file("${path.module}/snat.sh"),
          permissions : "0755",
        },
        {
          path : "/etc/systemd/system/snat.service",
          content : file("${path.module}/snat.service"),
        },
      ], var.user_data_write_files),
      runcmd : concat([
        ["/opt/nat/runonce.sh"],
      ], var.user_data_runcmd),
    })
  ]))

  description = "Launch template for NAT instance ${"${var.name}-1a"}"
  tags        = local.common_tags_1a
}

resource "aws_autoscaling_group" "zone1a" {
  name_prefix         = "${var.name}-1a"
  desired_capacity    = 1
  min_size            = 1 
  max_size            = 1
  availability_zones = ["us-east-1a"]

  mixed_instances_policy {
      launch_template {
        launch_template_specification {
          launch_template_id = aws_launch_template.zone1a.id
          version            = "$Latest"
        }
      }
    }
    
  lifecycle {
    create_before_destroy = true
  }
}

### Routes

resource "aws_route" "zone1a" {
    route_table_id     = module.vpc.private_route_table_ids[0]
#   route_table_id = "rtb-08893d79115607cf1"
    destination_cidr_block = "0.0.0.0/0"
    network_interface_id   = "${aws_network_interface.zone1a.id}"
}

#NAT Instance Zone 1b = zone1b

## Security Groups Roles

resource "aws_security_group" "zone1b" {
  name_prefix = "${var.name}-1b"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for NAT instance ${var.name}-1b"
  tags        = local.common_tags_1b
}

resource "aws_security_group_rule" "egress-zone1b" {
  security_group_id = aws_security_group.zone1b.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
}

resource "aws_security_group_rule" "ingress_any-zone1b" {
  description       = "Subnet-Private-EKS-AZ-1B"
  security_group_id = aws_security_group.zone1b.id
  type              = "ingress"
  cidr_blocks       = slice(var.private_subnets_cidr_blocks, 1, 2)
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
}

resource "aws_security_group_rule" "ingress_sf-zone1b" {
  description       = "Subnet-Private-SF-AZ-1B"
  security_group_id = aws_security_group.zone1b.id
  type              = "ingress"
  cidr_blocks       = slice(var.elasticache_subnets_cidr_blocks, 1, 2)
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
}

resource "aws_security_group_rule" "ingress_HUB-zone1b" {
  description       = "Subnet-Private-VPC-Hub-1B"
  security_group_id = aws_security_group.zone1b.id
  type              = "ingress"
  cidr_blocks       = slice(var.redshift_subnets_cidr_blocks, 1, 2)
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
}

## EIP Public

resource "aws_network_interface" "zone1b" {
  source_dest_check = false 
  subnet_id         = module.vpc.public_subnets[1]
  security_groups   = [aws_security_group.zone1b.id]

  tags = merge(var.tags, { "Name" = "${var.name}-1b" })
}

resource "aws_eip" "eip-zone1b" {
  public_ipv4_pool = "amazon"
  vpc = true
  network_interface = "${aws_network_interface.zone1b.id}"

  tags = merge(var.tags, { "Name" = "${var.name}-1b" })
}

## Nat_Instance

resource "aws_iam_instance_profile" "zone1b" {
  name_prefix = "${var.name}-1b"
  role        = aws_iam_role.zone1b.name
}

resource "aws_iam_role" "zone1b" {
  name_prefix        = "${var.name}-1b"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "ssm-zone1b" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.zone1b.name
}

resource "aws_iam_role_policy" "eni-zone1b" {
  role        = aws_iam_role.zone1b.name
  name_prefix = "${var.name}-1b"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AttachNetworkInterface",
                "ec2:ModifyInstanceAttribute"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}


resource "aws_launch_template" "zone1b" {
  name_prefix          = "${var.name}-1b"
  image_id             = var.image_id
  #key_name             = var.key_name
  instance_type        = var.instance_types

  iam_instance_profile {
    arn = aws_iam_instance_profile.zone1b.arn
  }

  network_interfaces {
    device_index = 0
    network_interface_id = "${aws_network_interface.zone1b.id}"
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 10
      volume_type = "gp3"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.common_tags_1b
  }

  user_data = base64encode(join("\n", [
    "#cloud-config",
    yamlencode({
      # https://cloudinit.readthedocs.io/en/latest/topics/modules.html
      write_files : concat([
        {
          path : "/opt/nat/runonce.sh",
          content : templatefile("${path.module}/runonce.sh", { eni_id = aws_network_interface.zone1b.id }),
          permissions : "0755",
        },
        {
          path : "/opt/nat/snat.sh",
          content : file("${path.module}/snat.sh"),
          permissions : "0755",
        },
        {
          path : "/etc/systemd/system/snat.service",
          content : file("${path.module}/snat.service"),
        },
      ], var.user_data_write_files),
      runcmd : concat([
        ["/opt/nat/runonce.sh"],
      ], var.user_data_runcmd),
    })
  ]))

  description = "Launch template for NAT instance ${var.name}-1b"
  tags        = local.common_tags_1b
}

resource "aws_autoscaling_group" "zone1b" {
  name_prefix         = "${var.name}-1b"
  desired_capacity    = 1
  min_size            = 1 
  max_size            = 1
  availability_zones = ["us-east-1b"]

  mixed_instances_policy {
      launch_template {
        launch_template_specification {
          launch_template_id = aws_launch_template.zone1b.id
          version            = "$Latest"
        }
      }
    }
    
  lifecycle {
    create_before_destroy = true
  }
}

### Routes

resource "aws_route" "zone1b" {
    route_table_id     = module.vpc.private_route_table_ids[1]
#   route_table_id = "rtb-08893d79115607cf1"
    destination_cidr_block = "0.0.0.0/0"
    network_interface_id   = "${aws_network_interface.zone1b.id}"
}

#NAT Instance Zone 1c = zone1c

## Security Groups Roles

resource "aws_security_group" "zone1c" {
  name_prefix = "${var.name}-1c"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for NAT instance ${var.name}-1c"
  tags        = local.common_tags_1c
}

resource "aws_security_group_rule" "egress-zone1c" {
  security_group_id = aws_security_group.zone1c.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
}

resource "aws_security_group_rule" "ingress_any-zone1c" {
  description = "Subnet-Private-EKS-AZ-1C"
  security_group_id = aws_security_group.zone1c.id
  type              = "ingress"
  cidr_blocks       = slice(var.private_subnets_cidr_blocks, 2, 3)
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
}

resource "aws_security_group_rule" "ingress_sf-zone1c" {
  description       = "Subnet-Private-SF-AZ-1C"
  security_group_id = aws_security_group.zone1c.id
  type              = "ingress"
  cidr_blocks       = slice(var.elasticache_subnets_cidr_blocks, 2, 3)
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
}

## EIP Public

resource "aws_network_interface" "zone1c" {
  source_dest_check = false 
  subnet_id         = module.vpc.public_subnets[2]
  security_groups   = [aws_security_group.zone1c.id]

  tags = merge(var.tags, { "Name" = "${var.name}-1c" })
}

resource "aws_eip" "eip-zone1c" {
  public_ipv4_pool = "amazon"
  vpc = true
  network_interface = "${aws_network_interface.zone1c.id}"

  tags = merge(var.tags, { "Name" = "${var.name}-1c" })
}

## Nat_Instance

resource "aws_iam_instance_profile" "zone1c" {
  name_prefix = "${var.name}-1c"
  role        = aws_iam_role.zone1c.name
}

resource "aws_iam_role" "zone1c" {
  name_prefix        = "${var.name}-1c"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "ssm-zone1c" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.zone1c.name
}

resource "aws_iam_role_policy" "eni-zone1c" {
  role        = aws_iam_role.zone1c.name
  name_prefix = "${var.name}-1c"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AttachNetworkInterface",
                "ec2:ModifyInstanceAttribute"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}


resource "aws_launch_template" "zone1c" {
  name_prefix          = "${var.name}-1c"
  image_id             = var.image_id
  #key_name             = var.key_name
  instance_type        = var.instance_types

  iam_instance_profile {
    arn = aws_iam_instance_profile.zone1c.arn
  }

  network_interfaces {
    device_index = 0
    network_interface_id = "${aws_network_interface.zone1c.id}"
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 10
      volume_type = "gp3"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.common_tags_1c
  }

  user_data = base64encode(join("\n", [
    "#cloud-config",
    yamlencode({
      # https://cloudinit.readthedocs.io/en/latest/topics/modules.html
      write_files : concat([
        {
          path : "/opt/nat/runonce.sh",
          content : templatefile("${path.module}/runonce.sh", { eni_id = aws_network_interface.zone1c.id }),
          permissions : "0755",
        },
        {
          path : "/opt/nat/snat.sh",
          content : file("${path.module}/snat.sh"),
          permissions : "0755",
        },
        {
          path : "/etc/systemd/system/snat.service",
          content : file("${path.module}/snat.service"),
        },
      ], var.user_data_write_files),
      runcmd : concat([
        ["/opt/nat/runonce.sh"],
      ], var.user_data_runcmd),
    })
  ]))

  description = "Launch template for NAT instance ${var.name}-1c"
  tags        = local.common_tags_1c
}

resource "aws_autoscaling_group" "zone1c" {
  name_prefix         = "${var.name}-1c"
  desired_capacity    = 1
  min_size            = 1 
  max_size            = 1
  availability_zones = ["us-east-1c"]

  mixed_instances_policy {
      launch_template {
        launch_template_specification {
          launch_template_id = aws_launch_template.zone1c.id
          version            = "$Latest"
        }
      }
    }
    
  lifecycle {
    create_before_destroy = true
  }
}

### Routes

resource "aws_route" "zone1c" {
    route_table_id     = module.vpc.private_route_table_ids[2]
#   route_table_id = "rtb-08893d79115607cf1"
    destination_cidr_block = "0.0.0.0/0"
    network_interface_id   = "${aws_network_interface.zone1c.id}"
}