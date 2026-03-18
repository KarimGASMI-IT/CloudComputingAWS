terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

resource "aws_db_subnet_group" "tp7_db_subnet_group" {
  name       = "${var.project_prefix}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.project_prefix}-db-subnet-group"
    Project     = var.project
    Owner       = var.owner
    Environment = var.environment
    ManagedBy   = "Terraform"
    TP          = "TP7"
  }
}

resource "aws_security_group" "tp7_db_sg" {
  name        = "${var.project_prefix}-db-sg"
  description = "RDS access only from application security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from app security group"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_prefix}-db-sg"
    Project     = var.project
    Owner       = var.owner
    Environment = var.environment
    ManagedBy   = "Terraform"
    TP          = "TP7"
  }
}

resource "aws_db_instance" "tp7_postgres" {
  identifier                   = var.db_instance_identifier
  engine                       = "postgres"
  engine_version               = var.postgres_engine_version
  instance_class               = var.db_instance_class
  allocated_storage            = var.allocated_storage
  storage_type                 = "gp3"
  db_name                      = var.db_name
  username                     = var.db_username
  password                     = var.db_password
  port                         = 5432
  db_subnet_group_name         = aws_db_subnet_group.tp7_db_subnet_group.name
  vpc_security_group_ids       = [aws_security_group.tp7_db_sg.id]
  publicly_accessible          = false
  multi_az                     = false
  storage_encrypted            = true
  backup_retention_period      = var.backup_retention_period
  backup_window                = var.backup_window
  maintenance_window           = var.maintenance_window
  deletion_protection          = false
  skip_final_snapshot          = true
  auto_minor_version_upgrade   = true
  apply_immediately            = true
  performance_insights_enabled = false
  copy_tags_to_snapshot        = true

  tags = {
    Name        = var.db_instance_identifier
    Project     = var.project
    Owner       = var.owner
    Environment = var.environment
    ManagedBy   = "Terraform"
    TP          = "TP7"
  }
}
