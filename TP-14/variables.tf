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
  default = "tp14-karim"
}

variable "container_port" {
  type    = number
  default = 8080
}

variable "cpu" {
  type    = number
  default = 256
}

variable "memory" {
  type    = number
  default = 512
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "image_tag" {
  type    = string
  default = "v1"
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}