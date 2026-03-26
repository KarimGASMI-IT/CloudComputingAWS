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

############################
# CloudWatch Logs
############################

resource "aws_cloudwatch_log_group" "producer" {
  name              = "/aws/lambda/${var.project_name}-producer"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "consumer" {
  name              = "/aws/lambda/${var.project_name}-consumer"
  retention_in_days = 7
}

############################
# SQS + DLQ
############################

resource "aws_sqs_queue" "dlq" {
  name                      = "${var.project_name}-dlq"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "main" {
  name                       = "${var.project_name}-main"
  visibility_timeout_seconds = 30

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

############################
# IAM Roles
############################

resource "aws_iam_role" "producer_role" {
  name = "${var.project_name}-producer-role"

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

resource "aws_iam_role_policy" "producer_policy" {
  name = "${var.project_name}-producer-policy"
  role = aws_iam_role.producer_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.producer.arn}:*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = aws_sqs_queue.main.arn
      }
    ]
  })
}

resource "aws_iam_role" "consumer_role" {
  name = "${var.project_name}-consumer-role"

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

resource "aws_iam_role_policy" "consumer_policy" {
  name = "${var.project_name}-consumer-policy"
  role = aws_iam_role.consumer_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.consumer.arn}:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = aws_sqs_queue.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table_name}"
      }
    ]
  })
}

############################
# Lambda packaging
############################

data "archive_file" "producer_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_producer.py"
  output_path = "${path.module}/lambda_producer.zip"
}

data "archive_file" "consumer_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_consumer.py"
  output_path = "${path.module}/lambda_consumer.zip"
}

############################
# Lambda 1 Producer
############################

resource "aws_lambda_function" "producer" {
  function_name = "${var.project_name}-producer"
  role          = aws_iam_role.producer_role.arn
  handler       = "lambda_producer.lambda_handler"
  runtime       = "python3.12"
  filename      = data.archive_file.producer_zip.output_path
  timeout       = 10

  source_code_hash = data.archive_file.producer_zip.output_base64sha256

  environment {
    variables = {
      QUEUE_URL = aws_sqs_queue.main.id
    }
  }

  depends_on = [aws_cloudwatch_log_group.producer]
}

############################
# Lambda 2 Consumer
############################

resource "aws_lambda_function" "consumer" {
  function_name = "${var.project_name}-consumer"
  role          = aws_iam_role.consumer_role.arn
  handler       = "lambda_consumer.lambda_handler"
  runtime       = "python3.12"
  filename      = data.archive_file.consumer_zip.output_path
  timeout       = 10

  source_code_hash = data.archive_file.consumer_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table_name
    }
  }

  depends_on = [aws_cloudwatch_log_group.consumer]
}

resource "aws_lambda_event_source_mapping" "sqs_to_consumer" {
  event_source_arn = aws_sqs_queue.main.arn
  function_name    = aws_lambda_function.consumer.arn
  batch_size       = 1
  enabled          = true
}

############################
# API Gateway HTTP
############################

resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "producer_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.producer.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "post_items" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /items"
  target    = "integrations/${aws_apigatewayv2_integration.producer_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.producer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
