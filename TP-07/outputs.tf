output "db_instance_identifier" {
  description = "RDS instance identifier"
  value       = aws_db_instance.tp7_postgres.id
}

output "db_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.tp7_postgres.address
}

output "db_port" {
  description = "RDS port"
  value       = aws_db_instance.tp7_postgres.port
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.tp7_db_subnet_group.name
}

output "db_security_group_id" {
  description = "Database security group ID"
  value       = aws_security_group.tp7_db_sg.id
}
