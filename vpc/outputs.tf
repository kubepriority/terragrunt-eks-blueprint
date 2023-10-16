output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "database_subnets" {
  value = module.vpc.database_subnets
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

#Zone1a

output "eni_id_1a" {
  description = "ID of the ENI for the NAT instance"
  value       = aws_network_interface.zone1a.id
}

output "eni_private_ip_1a" {
  description = "Private IP of the ENI for the NAT instance"
  # workaround of https://github.com/terraform-providers/terraform-provider-aws/issues/7522
  value = tolist(aws_network_interface.zone1a.private_ips)[0]
}

output "sg_id_1a" {
  description = "ID of the security group of the NAT instance"
  value       = aws_security_group.zone1a.id
}

output "iam_role_name_1a" {
  description = "Name of the IAM role for the NAT instance"
  value       = aws_iam_role.zone1a.name
}

#Zone1c

output "eni_id_1b" {
  description = "ID of the ENI for the NAT instance"
  value       = aws_network_interface.zone1b.id
}

output "eni_private_ip_1b" {
  description = "Private IP of the ENI for the NAT instance"
  # workaround of https://github.com/terraform-providers/terraform-provider-aws/issues/7522
  value = tolist(aws_network_interface.zone1b.private_ips)[0]
}

output "sg_id_1b" {
  description = "ID of the security group of the NAT instance"
  value       = aws_security_group.zone1b.id
}

output "iam_role_name_1b" {
  description = "Name of the IAM role for the NAT instance"
  value       = aws_iam_role.zone1b.name
}

#Zone1c

output "eni_id_1c" {
  description = "ID of the ENI for the NAT instance"
  value       = aws_network_interface.zone1c.id
}

output "eni_private_ip_1c" {
  description = "Private IP of the ENI for the NAT instance"
  # workaround of https://github.com/terraform-providers/terraform-provider-aws/issues/7522
  value = tolist(aws_network_interface.zone1c.private_ips)[0]
}

output "sg_id_1c" {
  description = "ID of the security group of the NAT instance"
  value       = aws_security_group.zone1c.id
}

output "iam_role_name_1c" {
  description = "Name of the IAM role for the NAT instance"
  value       = aws_iam_role.zone1c.name
}


output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = module.vpc.private_route_table_ids
}