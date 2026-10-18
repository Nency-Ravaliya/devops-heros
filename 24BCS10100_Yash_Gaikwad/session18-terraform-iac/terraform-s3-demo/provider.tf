terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"

      # Kept on 6.22.x because 6.23 and newer read bucket tags through the S3 Control API,
      # which the Moto emulator used in README.md does not implement. Real AWS works with
      # any 6.x release, so widen this to "~> 6.0" when you deploy for real.
      version = "~> 6.22.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Credentials are never written here. On real AWS the provider reads them from the
  # environment (AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY) or from `aws configure`.

  default_tags {
    tags = {
      Project   = "terraform-s3-demo"
      ManagedBy = "Terraform"
      Owner     = "Yash Gaikwad 24BCS10100"
    }
  }

  # ---- Local emulator / offline switches --------------------------------------------
  # All of these stay false on real AWS. They are only turned on by emulator.tfvars
  # (apply against a local Moto server) or by -var offline_mode=true (plan with no network).
  s3_use_path_style           = var.use_emulator
  skip_credentials_validation = var.use_emulator || var.offline_mode
  skip_metadata_api_check     = var.use_emulator || var.offline_mode
  skip_requesting_account_id  = var.use_emulator || var.offline_mode

  dynamic "endpoints" {
    for_each = var.use_emulator ? [1] : []

    content {
      s3  = var.emulator_endpoint
      ec2 = var.emulator_endpoint
      sts = var.emulator_endpoint
      iam = var.emulator_endpoint
    }
  }
}
