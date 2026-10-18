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
