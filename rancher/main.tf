provider "kubernetes" {
  host                   = data.terraform_remote_state.eks_remote.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks_remote.outputs.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.eks_remote.outputs.cluster_name]
  }
}

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

#####################################################################
# RANCHER AWS ALB CONTROLLER
#####################################################################

resource "kubernetes_namespace" "cattle_system" {
  metadata {
    name = "cattle-system"
  }
}

resource "kubernetes_secret" "tls_ca" {
  metadata {
    name      = "tls-ca"
    namespace = kubernetes_namespace.cattle_system.metadata[0].name
  }

  data = {
    "cacerts.pem" = file("${path.module}/cacerts.pem")
  }

  type = "generic"
}

resource "helm_release" "rancher" {
  name       = "rancher"
  repository = "https://releases.rancher.com/server-charts/stable"
  chart      = "rancher"
  namespace  = "cattle-system"
  version    = "2.7.6"
  create_namespace = true

  values = [
    file("${path.module}/values.yaml")
  ]  

}

resource "null_resource" "apply_ingress" {
  count = var.enable_alb_ingress ? 1 : 0

  triggers = { 
    manifest_yaml = "${path.module}/rancher-ingress-alb.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${self.triggers.manifest_yaml}"
  }
}