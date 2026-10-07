# Remote-state + locking demo: uses the S3 bucket and DynamoDB table created
# by ../ (apply that first) as a Terraform backend on LocalStack.
#   terraform init && terraform apply -auto-approve   (terminal 1, sleeps 25s)
#   terraform apply -auto-approve                      (terminal 2 -> lock error)
terraform {
  required_version = ">= 1.6"

  backend "s3" {
    bucket         = "stockpilot-dev-artifacts-24BCS10106"
    key            = "tfstate/backend-demo.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "stockpilot-dev-tf-locks"
    encrypt        = true

    # LocalStack settings - remove these for real AWS
    access_key                  = "test"
    secret_key                  = "test"
    use_path_style              = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    endpoints = {
      s3       = "http://localhost:4566"
      dynamodb = "http://localhost:4566"
    }
  }
}

variable "hold_seconds" {
  type    = number
  default = 25
}

# Built-in resource (no provider): runs long enough to hold the state lock.
resource "terraform_data" "release_marker" {
  input = "stockpilot-backend-demo"

  provisioner "local-exec" {
    command = "sleep ${var.hold_seconds}"
  }
}

output "marker" {
  value = terraform_data.release_marker.output
}
