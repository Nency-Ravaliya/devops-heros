# ---------------------------------------------------------------------------
# REMOTE STATE (example - intentionally commented out)
#
# This project uses LOCAL state (terraform.tfstate in this folder, git-ignored).
# For a team you would store state remotely so everyone shares one copy and
# concurrent runs are locked. Typical AWS setup:
#
#   1. Create (once, outside this project) a versioned + encrypted S3 bucket.
#   2. Uncomment the block below and run:  terraform init -migrate-state
#
# Since Terraform 1.10 the S3 backend can lock using an S3 lock file
# (use_lockfile = true). Older setups use a DynamoDB table with a "LockID"
# string partition key (dynamodb_table = "...") - now deprecated.
#
# Backend blocks cannot use variables, so values are literal.
# ---------------------------------------------------------------------------

# terraform {
#   backend "s3" {
#     bucket       = "Dhruv-24BCS10204-tfstate"
#     key          = "session19/mini-project/terraform.tfstate"
#     region       = "ap-south-1"
#     encrypt      = true
#     use_lockfile = true
#     # dynamodb_table = "terraform-locks"   # legacy locking alternative
#
#     # Only when testing against LocalStack:
#     # endpoints                   = { s3 = "http://localhost:4566" }
#     # use_path_style              = true
#     # skip_credentials_validation = true
#     # skip_requesting_account_id  = true
#     # access_key                  = "test"
#     # secret_key                  = "test"
#   }
# }
