locals {
  common_tags = {
    Project     = "TP-Cloud"
    Owner       = var.owner
    Environment = var.environment
    TP          = "15"
    ManagedBy   = "Terraform"
    CostCenter  = "Education"
  }
}