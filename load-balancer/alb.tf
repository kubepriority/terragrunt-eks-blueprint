provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.eks_remote.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.eks_remote.outputs.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.eks_remote.outputs.cluster_name]
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = data.terraform_remote_state.eks_remote.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks_remote.outputs.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.eks_remote.outputs.cluster_name]
  }
}

locals {
  name   = var.cluster_name
  region = var.aws_region

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}

################################################################################
# EKS NGINX CONFIG
################################################################################

resource "aws_security_group" "ingress_nginx_external" {
  name        = "ingress-nginx-external"
  description = "Allow public HTTP and HTTPS traffic"
  vpc_id      = data.terraform_remote_state.remote.outputs.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # modify to your requirements
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # modify to your requirements
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_security_group_rule" "allow_alb_traffic" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ingress_nginx_external.id
  security_group_id        = data.terraform_remote_state.eks_remote.outputs.node_security_group_id
}

resource "aws_security_group_rule" "allow_health_check_traffic" {
  type                     = "ingress"
  from_port                = 10254
  to_port                  = 10254
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ingress_nginx_external.id
  security_group_id        = data.terraform_remote_state.eks_remote.outputs.node_security_group_id
}

resource "aws_lb" "nginx_ingress" {
  name               = "nginx-ingress-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ingress_nginx_external.id]
  enable_deletion_protection = false
  subnets            = data.terraform_remote_state.remote.outputs.public_subnets

  enable_cross_zone_load_balancing = true
}

resource "aws_lb_target_group" "nginx_ingress_https" {
  name     = "nginx-ingress-https-tg"
  port     = 443
  protocol = "HTTPS" 
  vpc_id   =  data.terraform_remote_state.remote.outputs.vpc_id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/healthz"
    port                = "10254"
    protocol            = "HTTP"
    timeout             = 6
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200,301"
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  for_each                = toset(data.terraform_remote_state.eks_remote.outputs.eks_managed_node_groups_autoscaling_group_names)
  autoscaling_group_name  = each.value
  lb_target_group_arn     = aws_lb_target_group.nginx_ingress_https.arn

}

resource "aws_lb_listener" "frontend_https" {
  load_balancer_arn = aws_lb.nginx_ingress.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08" 
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_ingress_https.arn
  }
}


resource "aws_lb_listener" "frontend_http" {
  load_balancer_arn = aws_lb.nginx_ingress.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTP"
      status_code = "HTTP_301"
    }
  }
}

################################################################################
# HELM NGINX CONTROLLER
################################################################################

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  namespace  = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.hostNetwork"
    value = "true"
  }

  set {
    name  = "controller.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "controller.kind"
    value = "DaemonSet"
  }

  set {
    name  = "controller.daemonset.useHostPort"
    value = "true"
  }

  set {
    name  = "controller.watchIngressWithoutClass"
    value = "true"
  }

  set {
    name  = "controller.resources.limits.cpu"
    value = "200m" 
  }

  set {
    name  = "controller.resources.limits.memory"
    value = "256Mi" 
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = "100m" 
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "128Mi" 
  }

  set {
    name  = "controller.metrics.enabled"
    value = "true"
  }

  set {
    name  = "controller.logLevel"
    value = "2"
  }

}
