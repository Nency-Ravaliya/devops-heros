data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source              = "terraform-aws-modules/vpc/aws"
  version             = "5.8.1"
  name                = "taskboard-vpc"
  cidr                = "10.20.0.0/16"
  azs                 = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets     = ["10.20.1.0/24", "10.20.2.0/24"]
  public_subnets      = ["10.20.101.0/24", "10.20.102.0/24"]
  enable_nat_gateway  = true
  single_nat_gateway  = true
  public_subnet_tags  = { "kubernetes.io/role/elb" = "1" }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = "1" }
}

module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "20.37.1"
  cluster_name                             = var.cluster_name
  cluster_version                          = var.kubernetes_version
  vpc_id                                   = module.vpc.vpc_id
  subnet_ids                               = module.vpc.private_subnets
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true
  eks_managed_node_groups = {
    main = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 4
      desired_size   = 2
    }
  }
}
