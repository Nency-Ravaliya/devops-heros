# Non-secret values. The secret (app_secret) is passed with TF_VAR_app_secret instead.
aws_region   = "ap-south-1"
project_name = "cloud-demo"
environment  = "dev"

# 203.0.113.0/24 is a documentation range (TEST-NET-3): replace it with your own public IP,
# for example "198.51.100.7/32" (find it with: curl https://checkip.amazonaws.com).
ssh_cidr = "203.0.113.10/32"

instance_type  = "t3.micro"
instance_count = 1

# For real AWS, set a real Amazon Linux 2023 AMI for the region (see variables.tf).
# The default in variables.tf is a fake id that only the emulator accepts.
# ami_id = "ami-xxxxxxxxxxxxxxxxx"

bucket_suffix = "dev01"
