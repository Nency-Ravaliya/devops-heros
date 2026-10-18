variable "aws_region" {
  description = "AWS region where the bucket is created."
  type        = string
  default     = "ap-south-1"
}

variable "bucket_prefix" {
  description = "Fixed part of the bucket name. S3 names are global, so it carries my roll number."
  type        = string
  default     = "yash-24bcs10100-tf-demo"
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

variable "environment" {
  description = "Environment tag written on the bucket."
  type        = string
  default     = "dev"
}

variable "enable_versioning" {
  description = "Keep old versions of every object (Enabled) or stop doing so (Suspended)."
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allow terraform destroy to delete a bucket that still holds objects. Fine for a demo, dangerous for real data."
  type        = bool
  default     = true
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
