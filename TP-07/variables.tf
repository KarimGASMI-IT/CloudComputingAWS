variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "aws_profile" {
  description = "AWS CLI/Terraform profile"
  type        = string
  default     = "admin"
}

variable "project_prefix" {
  description = "Short prefix used in resource names"
  type        = string
  default     = "tp7-karim"
}

variable "project" {
  description = "Project tag"
  type        = string
  default     = "TP-Cloud"
}

variable "owner" {
  description = "Owner tag"
  type        = string
  default     = "ops-student"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "Training"
}

variable "vpc_id" {
  description = "Existing VPC ID from TP3"
  type        = string
}

variable "private_subnet_ids" {
  description = "Two private subnet IDs from TP3"
  type        = list(string)
}

variable "app_security_group_id" {
  description = "Application EC2 security group ID allowed to access the database"
  type        = string
}

variable "db_instance_identifier" {
  description = "RDS instance identifier"
  type        = string
  default     = "tp7-postgres-private"
}

variable "postgres_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.4"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Storage in GiB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "tp7db"
}

variable "db_username" {
  description = "Master username"
  type        = string
  default     = "tp7admin"
}

variable "db_password" {
  description = "Master password"
  type        = string
  sensitive   = true
}

variable "backup_retention_period" {
  description = "Automatic backup retention in days"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred backup window in UTC"
  type        = string
  default     = "02:00-03:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window in UTC"
  type        = string
  default     = "sun:03:00-sun:04:00"
}
