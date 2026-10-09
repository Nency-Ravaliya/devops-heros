locals {
  tags = merge({
    Project   = "taskboard"
    ManagedBy = "terraform"
  }, var.tags)

  cluster_name = "${var.name}-eks"
}

data "aws_partition" "current" {}

# KMS key used for EKS secrets envelope encryption, ECR images and CloudWatch logs.
resource "aws_kms_key" "this" {
  description             = "${var.name} - EKS secrets, ECR and log encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms.json

  tags = merge(local.tags, { Name = "${var.name}-kms" })
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.this.key_id
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "kms" {
  #checkov:skip=CKV_AWS_109:Key policy must grant the account root full control (AWS default pattern)
  #checkov:skip=CKV_AWS_111:Key policy must grant the account root full control (AWS default pattern)
  #checkov:skip=CKV_AWS_356:"*" in a key policy refers to this key only
  statement {
    sid       = "AccountRoot"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid = "CloudWatchLogs"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}
