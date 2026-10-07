# ---------------------------------------------------------------------------
# OPTIONAL: run this project against a local AWS mock (Moto / LocalStack)
# instead of a real AWS account. Copy it into the project root:
#
#   cp local-mock/mock_aws_override.tf .
#
# Terraform merges *_override.tf files into the provider block, so the
# real .tf files stay unchanged. Delete the copy to target real AWS again.
# ---------------------------------------------------------------------------

provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  s3_use_path_style           = true

  endpoints {
    ec2 = "http://localhost:4566"
    s3  = "http://localhost:4566"
    sts = "http://localhost:4566"
    iam = "http://localhost:4566"
    ssm = "http://localhost:4566"
  }
}
