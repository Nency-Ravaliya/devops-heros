# ---------------------------------------------------------------------------
# EKS control plane + managed node group (private subnets).
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "eks" {
  count             = var.enable_eks ? 1 : 0
  name              = "/aws/eks/${local.cluster_name}/cluster" # name EKS expects
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.this.arn
  tags              = local.tags
}

resource "aws_eks_cluster" "this" {
  #checkov:skip=CKV_AWS_39:Public endpoint is needed for kubectl from a laptop / GitHub runner; restricted via public_access_cidrs
  #checkov:skip=CKV_AWS_38:CIDRs come from var.cluster_endpoint_public_access_cidrs - set it to your /32 (see terraform.tfvars.example)
  count    = var.enable_eks ? 1 : 0
  name     = local.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.cluster[0].arn

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    subnet_ids              = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }

  # Envelope-encrypt Kubernetes Secrets with our KMS key.
  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.this.arn
    }
  }

  # EKS access entries: whoever runs `terraform apply` becomes cluster admin.
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = merge(local.tags, { Name = local.cluster_name })

  depends_on = [
    aws_iam_role_policy_attachment.cluster,
    aws_cloudwatch_log_group.eks,
  ]
}

resource "aws_launch_template" "nodes" {
  #checkov:skip=CKV_AWS_341:Hop limit 2 is the AWS-recommended value for EKS so the VPC CNI / pods can reach IMDSv2
  count       = var.enable_eks && var.enable_node_group ? 1 : 0
  name_prefix = "${var.name}-node-"
  description = "EKS managed node group template for ${local.cluster_name}"

  # When a launch template sets SGs, EKS no longer adds its cluster SG for us.
  vpc_security_group_ids = compact([
    aws_security_group.nodes.id,
    try(aws_eks_cluster.this[0].vpc_config[0].cluster_security_group_id, ""),
  ])

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 2          # allow pods (aws-node) to reach IMDS
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.node_disk_size
      volume_type           = "gp3"
      encrypted             = true # AWS-managed aws/ebs key
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.tags, { Name = "${var.name}-node" })
  }

  tags = local.tags
}

resource "aws_eks_node_group" "default" {
  count           = var.enable_eks && var.enable_node_group ? 1 : 0
  cluster_name    = aws_eks_cluster.this[0].name
  node_group_name = "${var.name}-default"
  node_role_arn   = aws_iam_role.nodes[0].arn
  subnet_ids      = aws_subnet.private[*].id

  instance_types = var.node_instance_types
  capacity_type  = var.node_capacity_type

  # Launch template: attaches our node SG, enforces IMDSv2 and encrypted gp3 root volumes.
  launch_template {
    id      = aws_launch_template.nodes[0].id
    version = aws_launch_template.nodes[0].latest_version
  }

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    workload = "taskboard"
  }

  tags = merge(local.tags, { Name = "${var.name}-node" })

  # Let the cluster-autoscaler / HPA-driven scaling change desired_size freely.
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [aws_iam_role_policy_attachment.nodes]
}
