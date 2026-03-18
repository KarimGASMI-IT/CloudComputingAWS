region         = "eu-west-3"
aws_profile    = "admin"
project_prefix = "tp7-karim"

# ===== INFRA EXISTANTE (TP3 / TP4 / TP5) =====
vpc_id = "vpc-046a2f76be9df76ef"

private_subnet_ids = [
  "subnet-0856f49e439746df8",
  "subnet-00327ef5f5b67f257"
]

app_security_group_id = "sg-0ece19e9c0dfde6fe"

# ===== CONFIG RDS =====
db_instance_identifier = "tp7-postgres-private"

db_name     = "tp7db"
db_username = "tp7admin"
db_password = "admin1234*" 

postgres_engine_version = "16.4"
db_instance_class       = "db.t3.micro"
allocated_storage       = 20

backup_retention_period = 7
backup_window           = "02:00-03:00"
maintenance_window      = "sun:03:00-sun:04:00"
