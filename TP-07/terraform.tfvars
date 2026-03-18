region                 = "eu-west-3"
aws_profile            = "admin"
project_prefix         = "tp7-karim"

# Ressources existantes du TP3 / TP4
vpc_id                 = "vpc-xxxxxxxxxxxxxxxxx"
private_subnet_ids     = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-yyyyyyyyyyyyyyyyy"]
app_security_group_id  = "sg-xxxxxxxxxxxxxxxxx"

# Paramètres RDS
db_instance_identifier = "tp7-postgres-private"
db_name                = "tp7db"
db_username            = "tp7admin"
db_password            = "ChangeMe1234!"

postgres_engine_version = "16.4"
db_instance_class       = "db.t3.micro"
allocated_storage       = 20
backup_retention_period = 7
backup_window           = "02:00-03:00"
maintenance_window      = "sun:03:00-sun:04:00"
