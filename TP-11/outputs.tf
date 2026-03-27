output "dashboard_name" {
  value = aws_cloudwatch_dashboard.main.dashboard_name
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "cloudtrail_name" {
  value = aws_cloudtrail.main.name
}

output "cloudtrail_log_group" {
  value = aws_cloudwatch_log_group.cloudtrail.name
}

output "flow_logs_group" {
  value = aws_cloudwatch_log_group.flow_logs.name
}