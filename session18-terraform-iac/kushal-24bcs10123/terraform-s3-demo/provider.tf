# One provider block that works against two targets:
#   * real AWS        -> leave aws_endpoint_url unset (default). Credentials come from
#                        ~/.aws/credentials / env vars exactly like the professor's demo.
#   * LocalStack      -> terraform apply -var-file=localstack.tfvars
#                        every skip_* / endpoint line below only switches on in that case.
provider "aws" {
  region = var.aws_region

  # ---- LocalStack only (all of this is null/false on real AWS) ----
  access_key                  = var.aws_endpoint_url == null ? null : "test"
  secret_key                  = var.aws_endpoint_url == null ? null : "test"
  skip_credentials_validation = var.aws_endpoint_url != null
  skip_metadata_api_check     = var.aws_endpoint_url != null
  skip_requesting_account_id  = var.aws_endpoint_url != null
  skip_region_validation      = var.aws_endpoint_url != null
  s3_use_path_style           = var.aws_endpoint_url != null # http://localhost:4566/<bucket> instead of <bucket>.localhost

  dynamic "endpoints" {
    for_each = var.aws_endpoint_url == null ? [] : [var.aws_endpoint_url]
    content {
      s3  = endpoints.value
      sts = endpoints.value
      iam = endpoints.value
    }
  }
}
