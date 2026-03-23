output "lambda_function_name" {
  value = aws_lambda_function.s3_validator.function_name
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda_exec.arn
}

output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.lambda_logs.name
}
