data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ecs_cluster" "tp14" {
  cluster_name = var.tp14_ecs_cluster_name
}

data "aws_lb" "tp14" {
  name = var.alb_name
}

data "aws_lb_target_group" "tp14" {
  name = var.target_group_name
}