terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Local state for the LocalStack demo. On real AWS this would be:
  # backend "s3" {
  #   bucket         = "stockpilot-tfstate-<account-id>"
  #   key            = "stockpilot/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "stockpilot-tf-locks"   # created by this config
  #   encrypt        = true
  # }
}
