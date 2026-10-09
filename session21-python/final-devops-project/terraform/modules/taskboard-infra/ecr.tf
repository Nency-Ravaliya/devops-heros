# ---------------------------------------------------------------------------
# ECR repositories - an AWS-native alternative to GHCR for the TaskBoard
# images. Nodes can pull from them via AmazonEC2ContainerRegistryReadOnly.
# ---------------------------------------------------------------------------
resource "aws_ecr_repository" "this" {
  for_each = toset(var.ecr_repositories)

  name = each.value
  # CI pushes immutable git-SHA tags; mutable "latest" is not used for deploys.
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true # allow `terraform destroy` even with images inside (demo only)

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.this.arn
  }

  tags = merge(local.tags, { Name = each.value })
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only the last ${var.ecr_keep_last_images} images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.ecr_keep_last_images
      }
      action = { type = "expire" }
    }]
  })
}
