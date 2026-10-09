terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

locals {
  # true when pointing at a local AWS emulator (Moto / LocalStack) instead of real AWS
  use_emulator = var.aws_endpoint_url != ""
}

provider "aws" {
  region = var.aws_region

  # Emulator settings: ignored (left at defaults) when aws_endpoint_url is empty
  s3_use_path_style           = local.use_emulator
  skip_credentials_validation = local.use_emulator
  skip_requesting_account_id  = local.use_emulator
  skip_metadata_api_check     = local.use_emulator

  endpoints {
    s3  = local.use_emulator ? var.aws_endpoint_url : null
    sts = local.use_emulator ? var.aws_endpoint_url : null
  }
}
