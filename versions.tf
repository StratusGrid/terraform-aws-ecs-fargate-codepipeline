# Terraform and Provider versions
terraform {
  required_version = ">= 1.2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.9.0"
    }
  }
}
