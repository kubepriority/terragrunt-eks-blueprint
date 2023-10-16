variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16" # valor genérico
}

variable "enabled" {
  description = "Enable or not costly resources"
  type        = bool
  default     = true
}

variable "name" {
  description = "Nome para todos os recursos como identificador"
  type        = string
  default     = "default-name" # valor genérico
}

variable "public_subnets_cidr_blocks" {
  description = "List of CIDR blocks of the public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"] # valores genéricos
}

variable "private_subnets_cidr_blocks" {
  description = "List of CIDR blocks of the private subnets. The NAT instance accepts connections from this subnets"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"] # valores genéricos
}

variable "database_subnets_cidr_blocks" {
  description = "List of CIDR blocks of the database subnets. The NAT instance accepts connections from this subnets"
  type        = list(string)
  default     = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24"] # valores genéricos
}

variable "elasticache_subnets_cidr_blocks" {
  description = "List of CIDR blocks of the infra subnets. The NAT instance accepts connections from this subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"] # valores genéricos
}

variable "redshift_subnets_cidr_blocks" {
  description = "List of CIDR blocks of the infra subnets. The NAT instance accepts connections from this subnets"
  type        = list(string)
  default     = ["10.0.13.0/24", "10.0.14.0/24"] # valores genéricos
}

variable "image_id" {
  description = "AMI of the NAT instance. Default to the latest Amazon Linux 2"
  type        = string
  default     = "ami-0c55b159cbfafe1f0" # Exemplo de valor padrão, verifique a AMI correta
}

variable "instance_types" {
  description = "Candidates of spot instance type for the NAT instance. This is used in the mixed instances policy"
  type        = string
  default     = "t3.micro" # Exemplo de valor padrão, altere conforme necessário
}

variable "use_spot_instance" {
  description = "Whether to use spot or on-demand EC2 instance"
  type        = bool
  default     = true
}

variable "key_name" {
  description = "Name of the key pair for the NAT instance. You can set this to assign the key pair to the NAT instance"
  type        = string
  default     = "default-key" # valor genérico
}

variable "user_data_write_files" {
  description = "Additional write_files section of cloud-init"
  type        = list(any)
  default     = []
}

variable "user_data_runcmd" {
  description = "Additional runcmd section of cloud-init"
  type        = list(list(string))
  default     = []
}

variable "tags" {
  description = "Tags applied to resources created with this module"
  type        = map(string)
  default     = {}
}

locals {
  common_tags_1a = merge(
    {
      Name = "nat-instance-${var.name}-1a"
    },
    var.tags,
  )
  common_tags_1b = merge(
    {
      Name = "nat-instance-${var.name}-1b"
    },
    var.tags,
  )
  common_tags_1c = merge(
    {
      Name = "nat-instance-${var.name}-1c"
    },
    var.tags,
  )
}

variable "ssm_policy_arn" {
  description = "SSM Policy to be attached to instance profile"
  type        = string
  default     = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}