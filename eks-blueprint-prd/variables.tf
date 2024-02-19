variable "aws_region" {
  description = "Name of the resource"
  type        = string
}

variable "cluster_name" {
  description = "Name of the resource"
  type        = string
}

variable "cluster_version" {
  type        = string
  description = "A versão do cluster EKS a ser utilizada."
  default = "1.26"
}

variable "certificate_arn" {
  description = "O ARN do certificado ACM a ser utilizado pelo Application Load Balancer"
  type        = string
  // default     = "" // Você pode definir um valor padrão ou deixar essa linha comentada para tornar a variável obrigatória.
}

variable "start_time_scale_up" {
  type        = string
  description = "Horário de início estático para a ação de escalonamento para cima"
  default     = "2023-10-15T08:00:00Z" # você pode definir um padrão ou deixar sem padrão se sempre quiser que seja especificado
}

variable "start_time_scale_down" {
  type        = string
  description = "Horário de início estático para a ação de escalonamento para baixo"
  default     = "2023-10-15T16:00:00Z" # você pode definir um padrão ou deixar sem padrão se sempre quiser que seja especificado
}