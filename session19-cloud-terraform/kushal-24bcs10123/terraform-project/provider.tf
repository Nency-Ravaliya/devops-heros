# Same pattern as session 18: plain real-AWS provider, with LocalStack switched on only when
# aws_endpoint_url is set (terraform apply -var-file=localstack.tfvars).
provider "aws" {
  region = var.aws_region

  access_key                  = var.aws_endpoint_url == null ? null : "test"
  secret_key                  = var.aws_endpoint_url == null ? null : "test"
  skip_credentials_validation = var.aws_endpoint_url != null
  skip_metadata_api_check     = var.aws_endpoint_url != null
  skip_requesting_account_id  = var.aws_endpoint_url != null
  skip_region_validation      = var.aws_endpoint_url != null
  s3_use_path_style           = var.aws_endpoint_url != null

  dynamic "endpoints" {
    for_each = var.aws_endpoint_url == null ? [] : [var.aws_endpoint_url]
    content {
      ec2 = endpoints.value
      s3  = endpoints.value
      sts = endpoints.value
      iam = endpoints.value
    }
  }

  default_tags {
    tags = {
      Project   = "session19"
      Owner     = "kushal-24bcs10123"
      ManagedBy = "Terraform"
    }
  }
}
