output "node_security_group_id" {
  value = module.eks.node_security_group_id 
}

output "eks_managed_node_groups_autoscaling_group_names" {
  value = module.eks.eks_managed_node_groups_autoscaling_group_names 
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "Configure o kubectl: certifique-se de estar logado com o perfil AWS correto e execute o seguinte comando para atualizar seu kubeconfig"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --alias ${module.eks.cluster_name} --region ${local.region}"
}