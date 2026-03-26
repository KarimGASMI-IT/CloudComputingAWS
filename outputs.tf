output "api_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

output "main_queue_url" {
  value = aws_sqs_queue.main.id
}

output "dlq_url" {
  value = aws_sqs_queue.dlq.id
}

output "producer_lambda" {
  value = aws_lambda_function.producer.function_name
}

output "consumer_lambda" {
  value = aws_lambda_function.consumer.function_name
}