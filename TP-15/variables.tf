variable "aws_region" {
  type    = string
  default = "eu-west-3"
}

variable "aws_profile" {
  type    = string
  default = "admin"
}

variable "project_name" {
  type    = string
  default = "tp15-karim"
}

variable "owner" {
  type    = string
  default = "Karim"
}

variable "environment" {
  type    = string
  default = "training"
}

variable "budget_limit_usd" {
  type    = string
  default = "15"
}

variable "budget_alert_email" {
  type = string
}

variable "tp14_ecs_cluster_name" {
  type        = string
  description = "Nom du cluster ECS existant du TP14"
  default     = "tp14-karim-cluster"
}

variable "tp14_ecs_service_name" {
  type        = string
  description = "Nom du service ECS existant du TP14"
  default     = "tp14-karim-service"
}

variable "alb_name" {
  type        = string
  description = "Nom de l'ALB existant du TP14"
}

variable "target_group_name" {
  type        = string
  description = "Nom du target group existant du TP14"
}

variable "resource_arns_to_tag" {
  type        = list(string)
  description = "Liste des ARN des ressources existantes à corriger côté tags"
  default     = []
}

variable "pra_bucket_name" {
  type        = string
  description = "Nom globalement unique du bucket S3 PRA"
}

variable "enable_incident_alarms" {
  type    = bool
  default = true
}