terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# LocalStack (local AWS emulator on port 4566), NOT a real AWS account.
# access_key/secret_key are LocalStack's dummy values.
# To use real AWS: remove access_key, secret_key, the skip_* flags,
# s3_use_path_style and the whole endpoints block, then use your own credentials.
provider "aws" {
  region     = var.aws_region
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  s3_use_path_style           = true

  endpoints {
    ec2 = var.localstack_endpoint
    s3  = var.localstack_endpoint
    sts = var.localstack_endpoint
  }

  default_tags {
    tags = {
      Project   = var.project_name
      Session   = "19"
      ManagedBy = "Terraform"
      Owner     = "piyush"
    }
  }
}

provider "random" {}
