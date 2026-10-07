# ---------------------------------------------------------------------------
# Remote state (recommended for teams / CI). Disabled by default so that a
# first `terraform init` works with local state.
#
# One-time bootstrap (creates the bucket + lock table, real AWS):
#
#   aws s3api create-bucket --bucket taskboard-tfstate-<account-id> \
#       --region ap-south-1 --create-bucket-configuration LocationConstraint=ap-south-1
#   aws s3api put-bucket-versioning --bucket taskboard-tfstate-<account-id> \
#       --versioning-configuration Status=Enabled
#   aws s3api put-bucket-encryption --bucket taskboard-tfstate-<account-id> \
#       --server-side-encryption-configuration \
#       '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms"}}]}'
#   aws s3api put-public-access-block --bucket taskboard-tfstate-<account-id> \
#       --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
#   aws dynamodb create-table --table-name taskboard-tf-locks \
#       --attribute-definitions AttributeName=LockID,AttributeType=S \
#       --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST
#
# Then uncomment the block below and run `terraform init -migrate-state`.
# (Terraform >= 1.10 can also lock with S3 itself: replace dynamodb_table
#  with `use_lockfile = true`.)
# ---------------------------------------------------------------------------

# terraform {
#   backend "s3" {
#     bucket         = "taskboard-tfstate-<account-id>"
#     key            = "final-devops-project/dev/terraform.tfstate"
#     region         = "ap-south-1"
#     dynamodb_table = "taskboard-tf-locks"
#     encrypt        = true
#   }
# }
