terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = "admin"
}

data "aws_caller_identity" "current" {}

##################################
# KMS KEY
##################################

resource "aws_kms_key" "main" {
  description             = "TP12 KMS key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-kms"
  target_key_id = aws_kms_key.main.id
}

##################################
# S3 CHIFFRE KMS
##################################

resource "aws_s3_bucket" "secure" {
  bucket = "${var.project_name}-secure-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secure" {
  bucket = aws_s3_bucket.secure.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.main.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

##################################
# SECRET MANAGER
##################################

resource "aws_secretsmanager_secret" "app" {
  name       = var.secret_name
  kms_key_id = aws_kms_key.main.arn
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id

  secret_string = jsonencode({
    username = "admin"
    password = "SuperSecret123!"
    token    = "tp12-token"
  })
}

##################################
# CLOUDWATCH LOG GROUP
##################################

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-secret-reader"
  retention_in_days = 7
}

##################################
# IAM ROLE LAMBDA
##################################

resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.lambda.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.app.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = aws_kms_key.main.arn
      }
    ]
  })
}

##################################
# LAMBDA ZIP
##################################

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_secret_reader.py"
  output_path = "${path.module}/lambda_secret_reader.zip"
}

##################################
# LAMBDA FUNCTION
##################################

resource "aws_lambda_function" "reader" {
  function_name = "${var.project_name}-secret-reader"
  role          = aws_iam_role.lambda.arn
  handler       = "lambda_secret_reader.lambda_handler"
  runtime       = "python3.12"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      SECRET_NAME = aws_secretsmanager_secret.app.name
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
}

##################################
# GUARDDUTY (OPTIONNEL)
##################################

resource "aws_guardduty_detector" "main" {
  count  = var.enable_guardduty ? 1 : 0
  enable = true
}
