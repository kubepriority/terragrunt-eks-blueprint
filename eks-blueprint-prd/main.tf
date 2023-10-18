provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

data "aws_availability_zones" "available" {}

locals {
  name   = var.name
  region = var.region

  #vpc_cidr = var.vpc_cidr
  #azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}

################################################################################
# Cluster
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.13"

  cluster_name                   = local.name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true

  vpc_id          = data.terraform_remote_state.remote.outputs.vpc_id
  subnet_ids      = data.terraform_remote_state.remote.outputs.private_subnets


    eks_managed_node_group_defaults = {
    iam_role_additional_policies = {
      # Not required, but used in the example to access the nodes to inspect mounted volumes
      AmazonSSMManagedInstanceCore   = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      ElasticLoadBalancingFullAccess = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
    }
  }

  #REF: https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/examples/eks_managed_node_group/main.tf
  eks_managed_node_groups = {
    core_node_group = {
      #name            = "Nodegroup-t3-xlarge-01"
      instance_types = ["t3.xlarge"]

      ami_type = "BOTTLEROCKET_x86_64"
      platform = "bottlerocket"

      min_size     = 1
      max_size     = 3
      desired_size = 1

      labels = {
        GithubRepo = "terraform-aws-eks"
        GithubOrg  = "terraform-aws-modules"
      }

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3"
            iops                  = 3000 
            throughput            = 125 
            delete_on_termination = true
          }
        }
      }

      # Definindo tags para o novo node group
      tags = {
        Name = "Nodegroup-t3-xlarge-01" 
      }

    }

    # Adicionando um novo node group
    additional_node_group = {
      #name            = "Nodegroup-t3-xlarge-02"
      instance_types = ["t3.xlarge"]

      ami_type = "BOTTLEROCKET_x86_64"
      platform = "bottlerocket"

      min_size     = 1 
      max_size     = 3 
      desired_size = 1 

      labels = {
        nodegroup = "temporario"
      }

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3"
            iops                  = 3000 
            throughput            = 125 
            delete_on_termination = true
          }
        }
      }

      schedules = {
        scale-up = {
          min_size     = 1
          max_size     = 3
          desired_size = 1
          start_time   = var.start_time_scale_up
          recurrence   = "0 8 * * MON-FRI"      # às 8h, de segunda a sexta
        },
        scale-down = {
          min_size     = 0
          desired_size = 0
          start_time   = var.start_time_scale_down 
          recurrence   = "0 18 * * MON-FRI"     # às 18h, de segunda a sexta
        }
      }

      # Definindo tags para o novo node group
      tags = {
        Name = "Nodegroup-t3-xlarge-02" 
      }
    }  

  }

  tags = local.tags
}

################################################################################
# EKS Blueprints Addons
################################################################################

module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0" #ensure to update this to the latest/desired version

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    set = [
      {
        name  = "vpcId"
        value = data.terraform_remote_state.remote.outputs.vpc_id
      },
      {
        name  = "podDisruptionBudget.maxUnavailable"
        value = 1
      },
      {
        name  = "enableServiceMutatorWebhook"
        value = "false"
      }
    ]
  }
  enable_cluster_autoscaler              = true
  enable_metrics_server                  = true
  enable_external_dns                    = true
  external_dns_route53_zone_arns         = ["arn:aws:route53:::hostedzone/Z09826242LD44BES3LPKM"]
  enable_cert_manager                    = true
  #cert_manager_route53_hosted_zone_arns  = ["arn:aws:route53:::hostedzone/Z09826242LD44BES3LPKM"]

  tags = {
    Environment = "prd"
  }
}


################################################################################
# Storage Classes
################################################################################

resource "kubernetes_annotations" "gp2" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  force       = "true"

  metadata {
    name = "gp2"
  }

  annotations = {
    # Modify annotations to remove gp2 as default storage class still reatain the class
    "storageclass.kubernetes.io/is-default-class" = "false"
  }
}


resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"

    annotations = {
      # Annotation to set gp3 as default storage class
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  allow_volume_expansion = true
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    encrypted = true
    fsType    = "ext4"
    type      = "gp3"
  }

}

################################################################################
# Managed USERS EKS
################################################################################

resource "aws_iam_role" "eks_admin_role" {
  name = "eks-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_admin_policy" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_group" "eks_admin_group" {
  name = "eks-admin-group"
}

resource "aws_iam_group_policy" "eks_admin_assume_role" {
  name  = "eks-admin-assume-role-policy"
  group = aws_iam_group.eks_admin_group.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Resource = aws_iam_role.eks_admin_role.arn
      },
    ]
  })
}

#Criando a identidade:
#eksctl create iamidentitymapping --cluster eks-treinamento-prd --arn arn:aws:iam::219469607196:group/eks-admin-group --group system:masters --username admin

resource "kubernetes_cluster_role_binding" "eks_admin_group_binding" {
  metadata {
    name = "eks-admin-group-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin" # system:masters é mapeado para cluster-admin em EKS
  }
  subject {
    kind      = "Group"
    name      = "system:masters" # Isso deve corresponder ao grupo definido no mapeamento de identidade IAM do EKS
    api_group = "rbac.authorization.k8s.io"
  }
}



################################################################################
# Supporting Resources
################################################################################

# Subnets - EKS

#resource "aws_subnet" "eks_subnet_1" {
#  vpc_id     = var.vpc_id
#  cidr_block = var.eks_subnet_cidr_1
#  availability_zone = "us-east-1b"
#  tags = {
#    Name = "usebens-prod-eks1"
#  }
#}
#
#resource "aws_subnet" "eks_subnet_2" {
#  vpc_id     = var.vpc_id
#  cidr_block = var.eks_subnet_cidr_2
#  availability_zone = "us-east-1c"
#  tags = {
#    Name = "usebens-prod-eks2"
#  }
#}


#module "vpc" {
#  source  = "terraform-aws-modules/vpc/aws"
#  version = "~> 5.0"
#
#  name = local.name
#  cidr = local.vpc_cidr
#
#  azs             = local.azs
#  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
#  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]
#
#  enable_nat_gateway = true
#  single_nat_gateway = true
#
#  manage_default_network_acl    = true
#  default_network_acl_tags      = { Name = "${local.name}-default" }
#  manage_default_route_table    = true
#  default_route_table_tags      = { Name = "${local.name}-default" }
#  manage_default_security_group = true
#  default_security_group_tags   = { Name = "${local.name}-default" }
#
#  public_subnet_tags = {
#    "kubernetes.io/role/elb" = 1
#  }
#
#  private_subnet_tags = {
#    "kubernetes.io/role/internal-elb" = 1
#  }
#
#  tags = local.tags
#}
