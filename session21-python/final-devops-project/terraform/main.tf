# ---------------------------------------------------------------------------
# TaskBoard - real AWS root module.
# All resources live in ./modules/taskboard-infra so that the exact same code
# can also be exercised against a local AWS mock (environments/local-mock).
# ---------------------------------------------------------------------------
module "taskboard" {
  source = "./modules/taskboard-infra"

  name = "taskboard-${var.environment}"
  tags = { Environment = var.environment }

  # network
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = [for i, _ in var.azs : cidrsubnet(var.vpc_cidr, 8, 101 + i)]
  private_subnet_cidrs = [for i, _ in var.azs : cidrsubnet(var.vpc_cidr, 8, 1 + i)]
  enable_nat_gateway   = var.enable_nat_gateway

  # EKS
  enable_eks                           = true
  enable_node_group                    = true
  kubernetes_version                   = var.kubernetes_version
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  node_instance_types                  = var.node_instance_types
  node_capacity_type                   = var.node_capacity_type
  node_desired_size                    = var.node_desired_size
  node_min_size                        = var.node_min_size
  node_max_size                        = var.node_max_size

  # ECR
  ecr_repositories = var.ecr_repositories
}
