output "kms_key_arn" {
  value = aws_kms_key.main.arn
}

output "kms_alias" {
  value = aws_kms_alias.main.name
}

output "s3_bucket" {
  value = aws_s3_bucket.secure.bucket
}

output "secret_name" {
  value = aws_secretsmanager_secret.app.name
}

output "secret_arn" {
  value = aws_secretsmanager_secret.app.arn
}

output "lambda_name" {
  value = aws_lambda_function.reader.function_name
}

output "guardduty_detector" {
  value = var.enable_guardduty ? aws_guardduty_detector.main[0].id : "GuardDuty disabled"
}