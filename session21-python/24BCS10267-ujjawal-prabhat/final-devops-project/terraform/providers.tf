provider "aws" {
  region = var.region

  # LocalStack accepts any credentials; on real AWS leave these null so the
  # normal credential chain (env vars / SSO / instance role) is used.
  access_key = var.use_localstack ? "test" : null
  secret_key = var.use_localstack ? "test" : null

  skip_credentials_validation = var.use_localstack
  skip_metadata_api_check     = var.use_localstack
  skip_requesting_account_id  = var.use_localstack
  s3_use_path_style           = var.use_localstack

  dynamic "endpoints" {
    for_each = var.use_localstack ? [1] : []
    content {
      ec2      = var.localstack_endpoint
      s3       = var.localstack_endpoint
      dynamodb = var.localstack_endpoint
      ecr      = var.localstack_endpoint
      iam      = var.localstack_endpoint
      sts      = var.localstack_endpoint
    }
  }

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      Owner       = "24BCS10267-ujjawal-prabhat"
      ManagedBy   = "terraform"
    }
  }
}
