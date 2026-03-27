variable "region" {
  default = "eu-west-3"
}

variable "project_name" {
  default = "tp12-karim-v2"
}

variable "secret_name" {
  default = "tp12-app-secret-v2"
}

variable "enable_guardduty" {
  description = "Activer GuardDuty si le compte le permet"
  type        = bool
  default     = false
}