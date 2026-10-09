terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
<<<<<<< HEAD
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
=======
>>>>>>> upstream/main
  }
}

provider "aws" {
  region = var.aws_region
}
