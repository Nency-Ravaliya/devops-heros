terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Upper bound for LocalStack 3.8 compatibility: newer 6.x releases send
      # bucket tags inside CreateBucket (S3 ABAC), which LocalStack 3.8 does
      # not reliably store -> tags missing + perpetual diff. 6.20 tags buckets
      # with a separate PutBucketTagging call. Drop the bound for real AWS.
      version = ">= 6.0, < 6.21"
    }
  }
}

# ---------------------------------------------------------------------------
# PROVIDER
# One provider block for both targets:
#   use_localstack = true  -> LocalStack (AWS emulator) on localhost:4566,
#                             dummy credentials, no account/credential checks
#   use_localstack = false -> real AWS with the normal credential chain
# ---------------------------------------------------------------------------
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
      ec2 = var.localstack_endpoint
      s3  = var.localstack_endpoint
      iam = var.localstack_endpoint
      sts = var.localstack_endpoint
    }
  }

  default_tags {
    tags = {
      Project   = var.project_name
      Session   = "19"
      Owner     = "24BCS10157"
      ManagedBy = "Terraform"
    }
  }
}
