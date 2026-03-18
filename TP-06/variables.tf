variable "region" {
  description = "Région AWS cible"
  type        = string
  default     = "eu-west-3"
}

variable "aws_profile" {
  description = "Profil AWS CLI/Terraform à utiliser"
  type        = string
  default     = "training"
}

variable "bucket_name" {
  description = "Nom globalement unique du bucket S3"
  type        = string
}

variable "project" {
  description = "Tag projet"
  type        = string
  default     = "TP-Cloud"
}

variable "owner" {
  description = "Tag owner"
  type        = string
  default     = "ops-student"
}

variable "environment" {
  description = "Tag environnement"
  type        = string
  default     = "Training"
}
