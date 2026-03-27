variable "region" {
  default = "eu-west-3"
}

variable "project_name" {
  default = "tp11-karim"
}

variable "api_name" {
  description = "Nom logique pour le dashboard"
  default     = "tp10-karim-api"
}

variable "api_gateway_id" {
  description = "ID API Gateway HTTP du TP10"
  type        = string
}

variable "producer_lambda_name" {
  type    = string
  default = "tp10-karim-producer"
}

variable "consumer_lambda_name" {
  type    = string
  default = "tp10-karim-consumer"
}

variable "dlq_name" {
  type    = string
  default = "tp10-karim-dlq"
}

variable "critical_vpc_id" {
  description = "VPC à superviser avec Flow Logs"
  type        = string
}

variable "alarm_email" {
  description = "Email pour recevoir les alarmes SNS"
  type        = string
}