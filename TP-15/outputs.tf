output "alb_dns_name" {
  value = data.aws_lb.tp14.dns_name
}

output "pra_bucket_name" {
  value = aws_s3_bucket.pra.bucket
}

output "budget_name" {
  value = aws_budgets_budget.project_budget.name
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.tp15.dashboard_name
}