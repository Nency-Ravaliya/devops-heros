data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  tags = {
    Project   = "stockpilot"
    ManagedBy = "terraform"
  }
}

# ---------------------------------------------------------------------------
# Network: one VPC, public subnets (load balancers, NAT) and private subnets
# (worker nodes), spread over several availability zones.
# ---------------------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr
  azs  = local.azs

  public_subnets  = [for index, _ in local.azs : cidrsubnet(var.vpc_cidr, 8, index)]
  private_subnets = [for index, _ in local.azs : cidrsubnet(var.vpc_cidr, 8, index + 10)]

  # private nodes reach the internet (image pulls, AWS APIs) through the NAT gateway
  enable_nat_gateway   = true
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = true

  # tells Kubernetes which subnets to use for internet-facing / internal load balancers
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

# ---------------------------------------------------------------------------
# EKS: managed control plane + one managed node group in the private subnets.
# ---------------------------------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  endpoint_public_access = var.endpoint_public_access

  # whoever runs `terraform apply` becomes cluster admin, so kubectl works straight away
  enable_cluster_creator_admin_permissions = true

  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
    # lets the PostgreSQL PersistentVolumeClaim create EBS volumes
    aws-ebs-csi-driver = {}
  }

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types

      min_size     = var.node_min_size
      desired_size = var.node_desired_size
      max_size     = var.node_max_size

      iam_role_additional_policies = {
        ebs_csi = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
  }
}
