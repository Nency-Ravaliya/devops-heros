terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# The same provider block works against real AWS and against LocalStack.
# When var.use_localstack = true, dummy credentials are used and every
# service endpoint is redirected to var.localstack_endpoint.
# When false, normal AWS credential resolution (env vars, ~/.aws, SSO, ...)
# and the real AWS endpoints are used.
provider "aws" {
  region = var.aws_region

  access_key = var.use_localstack ? "test" : null
  secret_key = var.use_localstack ? "test" : null

  skip_credentials_validation = var.use_localstack
  skip_metadata_api_check     = var.use_localstack
  skip_requesting_account_id  = var.use_localstack
  s3_use_path_style           = var.use_localstack

  dynamic "endpoints" {
    for_each = var.use_localstack ? [1] : []
    content {
      s3  = var.localstack_endpoint
      sts = var.localstack_endpoint
      iam = var.localstack_endpoint
    }
  }

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Session   = "18"
      Owner     = "24BCS10106"
    }
  }
}
