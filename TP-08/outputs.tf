output "table_name" { value = aws_dynamodb_table.tp8_orders.name }
output "stream_arn" { value = aws_dynamodb_table.tp8_orders.stream_arn }
