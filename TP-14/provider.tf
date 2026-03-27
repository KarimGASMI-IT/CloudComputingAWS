provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = "TP-Cloud"
      Owner       = "Karim"
      Environment = "training"
      TP          = "14"
    }
  }
}