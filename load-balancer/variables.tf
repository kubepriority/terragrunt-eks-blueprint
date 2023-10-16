variable "name" {
  description = "Name of the resource"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "certificate_arn" {
  description = "O ARN do certificado ACM a ser utilizado pelo Application Load Balancer"
  type        = string
  // default     = "" // Você pode definir um valor padrão ou deixar essa linha comentada para tornar a variável obrigatória.
}