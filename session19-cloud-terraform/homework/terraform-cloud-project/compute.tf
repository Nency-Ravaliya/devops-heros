resource "aws_instance" "web" {
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.web.name

  # Install nginx and serve index.html downloaded from S3 (uses the instance role, no keys)
  user_data = templatefile("${path.module}/templates/user-data.sh.tftpl", {
    bucket = aws_s3_bucket.site.bucket
    region = var.aws_region
  })
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  # Explicit dependency: the page must be in S3 and the route to the internet must exist
  # before the instance boots and runs user data.
  depends_on = [
    aws_s3_object.index,
    aws_route_table_association.public,
    aws_iam_role_policy.read_site,
  ]

  tags = { Name = "${var.project}-web" }
}
