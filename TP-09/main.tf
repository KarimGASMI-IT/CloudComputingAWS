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
  profile = var.profile
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/src/lambda_function.py"
  output_path = "${path.module}/build/lambda_function.zip"
}

data "aws_caller_identity" "current" {}

locals {
  input_prefix_arn  = "arn:aws:s3:::${var.bucket_name}/${var.input_prefix}*"
  output_prefix_arn = "arn:aws:s3:::${var.bucket_name}/${var.output_prefix}*"
  log_group_name    = "/aws/lambda/${var.lambda_function_name}"
}

resource "aws_iam_role" "lambda_exec" {
  name = var.lambda_role_name

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

  tags = {
    TP      = "09"
    Project = "CloudComputingAWS"
  }
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.lambda_function_name}-inline-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowReadInputPrefix"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectTagging"
        ]
        Resource = local.input_prefix_arn
      },
      {
        Sid    = "AllowWriteOutputPrefix"
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = local.output_prefix_arn
      },
      {
        Sid    = "AllowListBucketForPrefixes"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::${var.bucket_name}"
        Condition = {
          StringLike = {
            "s3:prefix" = [
              "${var.input_prefix}*",
              "${var.output_prefix}*"
            ]
          }
        }
      },
      {
        Sid    = "AllowLambdaLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.lambda_logs.arn}:*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_days

  tags = {
    TP      = "09"
    Project = "CloudComputingAWS"
  }
}

resource "aws_lambda_function" "s3_validator" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = var.lambda_runtime
  filename      = data.archive_file.lambda_zip.output_path

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      MAX_SIZE_BYTES     = tostring(var.max_size_bytes)
      ALLOWED_EXTENSIONS = join(",", var.allowed_extensions)
      OUTPUT_PREFIX      = var.output_prefix
      LOG_LEVEL          = "INFO"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs
  ]

  tags = {
    TP      = "09"
    Project = "CloudComputingAWS"
  }
}

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_validator.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.bucket_name}"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_validator.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.input_prefix
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}
