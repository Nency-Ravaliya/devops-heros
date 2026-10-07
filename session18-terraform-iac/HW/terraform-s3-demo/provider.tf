terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# This provider points at LocalStack (a local AWS emulator on port 4566),
# not a real AWS account. The credentials below are LocalStack's dummy values.
# To use real AWS: delete access_key/secret_key, the skip_* flags,
# s3_use_path_style and the whole endpoints block.
provider "aws" {
  region     = var.aws_region
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  s3_use_path_style           = true

  endpoints {
    s3  = var.localstack_endpoint
    sts = var.localstack_endpoint
  }
}
