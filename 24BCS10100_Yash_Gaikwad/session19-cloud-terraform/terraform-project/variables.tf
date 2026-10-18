# ---- General -----------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for every resource."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Short name used in resource names and tags."
  type        = string
  default     = "cloud-demo"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "extra_tags" {
  description = "Additional tags merged into the common tag set."
  type        = map(string)
  default     = {}
}

# ---- Network -----------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block such as 10.0.0.0/16."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR block of the public subnet (must sit inside vpc_cidr)."
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrnetmask(var.public_subnet_cidr))
    error_message = "public_subnet_cidr must be a valid IPv4 CIDR block such as 10.0.1.0/24."
  }
}

variable "availability_zone_suffix" {
  description = "Letter appended to the region to pick the Availability Zone (a gives ap-south-1a)."
  type        = string
  default     = "a"
}

variable "ssh_cidr" {
  description = "CIDR allowed to reach SSH (port 22). Use your own public IP as x.x.x.x/32."
  type        = string
  # No default on purpose: opening SSH must be a conscious choice.

  validation {
    condition     = can(cidrnetmask(var.ssh_cidr)) && var.ssh_cidr != "0.0.0.0/0"
    error_message = "ssh_cidr must be a valid IPv4 CIDR and must not be 0.0.0.0/0 (SSH open to the whole internet)."
  }
}

# ---- Compute -----------------------------------------------------------------------

variable "ami_id" {
  description = "AMI used for the web server."
  type        = string

  # FAKE placeholder: only the local emulator accepts it. Real AWS answers InvalidAMIID.NotFound,
  # so nothing can be created by accident. For real AWS look up a current Amazon Linux 2023 AMI
  # for your region, for example:
  #   aws ssm get-parameter --region ap-south-1 \
  #     --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
  #     --query Parameter.Value --output text
  default = "ami-00000000000000000"

  validation {
    condition     = can(regex("^ami-[0-9a-f]{8,17}$", var.ami_id))
    error_message = "ami_id must look like ami-0abc1234def567890."
  }
}

variable "instance_type" {
  description = "EC2 instance type (small burstable sizes only, as a cost guard)."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^t3\\.(nano|micro|small)$", var.instance_type))
    error_message = "instance_type must be t3.nano, t3.micro or t3.small."
  }
}

variable "instance_count" {
  description = "How many identical web servers to launch."
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 3
    error_message = "instance_count must be between 1 and 3."
  }
}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH. Leave null to launch without one."
  type        = string
  default     = null
}

# ---- Storage and secrets ------------------------------------------------------------

variable "bucket_prefix" {
  description = "Fixed part of the S3 bucket name. Bucket names are global, so it carries my roll number."
  type        = string
  default     = "yash-24bcs10100-s19-assets"
}

variable "bucket_suffix" {
  description = "Variable part of the bucket name. Change it if the name is already taken."
  type        = string
  default     = "dev01"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,20}$", var.bucket_suffix))
    error_message = "bucket_suffix must be 1 to 21 characters: lowercase letters, digits and hyphens, starting with a letter or digit."
  }
}

variable "app_secret" {
  description = "Secret the application reads at runtime. Supply it with TF_VAR_app_secret, never in a .tfvars file."
  type        = string
  sensitive   = true
  # No default: Terraform must be given it from the environment.
}

# ---- Local emulator / offline switches (see provider.tf) ----------------------------

variable "use_emulator" {
  description = "Send every API call to emulator_endpoint (a local Moto server) instead of AWS."
  type        = bool
  default     = false
}

variable "emulator_endpoint" {
  description = "URL of the local AWS emulator. Only used when use_emulator is true."
  type        = string
  default     = "http://localhost:5000"
}

variable "offline_mode" {
  description = "Skip every provider call that needs the network, so terraform plan works with dummy credentials. Real AWS is still the target."
  type        = bool
  default     = false
}
