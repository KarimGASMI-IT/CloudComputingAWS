aws_region  = "eu-west-3"
aws_profile = "admin"

project_name = "tp15-karim"

owner       = "Karim"
environment = "training"

budget_limit_usd   = "15"
budget_alert_email = "karimgasmi360@gmail.com"

tp14_ecs_cluster_name = "tp14-karim-cluster"
tp14_ecs_service_name = "tp14-karim-service"
alb_name              = "tp14-karim-alb"
target_group_name     = "tp14-karim-tg"

pra_bucket_name = "tp15-karim-pra-311493920732"

enable_incident_alarms = true

resource_arns_to_tag = [
  "arn:aws:elasticloadbalancing:eu-west-3:311493920732:loadbalancer/app/tp14-karim-alb/4d5014d21516fb1b",
  "arn:aws:elasticloadbalancing:eu-west-3:311493920732:targetgroup/tp14-karim-tg/90cbcedb3c3e2a16",
  "arn:aws:ecs:eu-west-3:311493920732:service/tp14-karim-cluster/tp14-karim-service"
]