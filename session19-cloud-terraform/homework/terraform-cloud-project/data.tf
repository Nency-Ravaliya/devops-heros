# First AZ in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Latest Amazon Linux 2023 AMI (x86_64), looked up instead of hard-coding an AMI ID
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# My current public IP, used only if allow_ssh = true
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}
