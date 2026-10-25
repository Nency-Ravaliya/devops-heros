# One provider block that works against real AWS and against LocalStack.
# With aws_endpoint_url = "" (the default) every custom-endpoint / skip_* setting below is
# inactive and the normal credential chain is used. Setting it to http://localhost:4566
# points every API call at LocalStack and turns the validation off that would otherwise
# call the real STS / IAM endpoints.
provider "aws" {
  region = var.aws_region

  access_key = var.aws_endpoint_url != "" ? "test" : null
  secret_key = var.aws_endpoint_url != "" ? "test" : null

  skip_credentials_validation = var.aws_endpoint_url != ""
  skip_metadata_api_check     = var.aws_endpoint_url != ""
  skip_requesting_account_id  = var.aws_endpoint_url != ""
  s3_use_path_style           = var.aws_endpoint_url != ""

  dynamic "endpoints" {
    for_each = var.aws_endpoint_url != "" ? [1] : []
    content {
      ec2 = var.aws_endpoint_url
      s3  = var.aws_endpoint_url
      iam = var.aws_endpoint_url
      sts = var.aws_endpoint_url
      eks = var.aws_endpoint_url
    }
  }

  default_tags {
    tags = {
      Project   = "studytrack"
      Owner     = "kushal-24bcs10123"
      ManagedBy = "terraform"
    }
  }
}
