variable "region" {
  type    = string
  default = "eu-west-3"
}

variable "profile" {
  type    = string
  default = "admin"
}

variable "bucket_name" {
  type        = string
  description = "Bucket S3 existant du TP-06"
}

variable "input_prefix" {
  type    = string
  default = "input/"
}

variable "output_prefix" {
  type    = string
  default = "output/"
}

variable "lambda_function_name" {
  type    = string
  default = "tp9-s3-validator"
}

variable "lambda_role_name" {
  type    = string
  default = "tp9-s3-validator-role"
}

variable "lambda_runtime" {
  type    = string
  default = "python3.11"
}

variable "lambda_timeout" {
  type    = number
  default = 10
}

variable "lambda_memory_size" {
  type    = number
  default = 128
}

variable "max_size_bytes" {
  type    = number
  default = 1048576
}

variable "allowed_extensions" {
  type    = list(string)
  default = [".txt", ".json", ".png"]
}

variable "log_retention_days" {
  type    = number
  default = 7
}
