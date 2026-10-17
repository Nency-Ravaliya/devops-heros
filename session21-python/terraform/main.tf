module "vpc" {
  source             = "terraform-aws-modules/vpc/aws"
  version            = "6.7.3"
  name               = "liftlog-vpc"
  cidr               = "10.20.0.0/16"
  azs                = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets    = ["10.20.1.0/24", "10.20.2.0/24"]
  public_subnets     = ["10.20.101.0/24", "10.20.102.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true

  # Tags so Kubernetes can place LoadBalancer services in the right subnets
  public_subnet_tags  = { "kubernetes.io/role/elb" = 1 }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = 1 }
}

module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "21.29.0"
  name                                     = var.cluster_name
  kubernetes_version                       = "1.36" # standard support; 1.31 is billed at the extended-support rate
  vpc_id                                   = module.vpc.vpc_id
  subnet_ids                               = module.vpc.private_subnets
  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true
  # IRSA needs an IAM OIDC provider, which this project's service control policy denies;
  # pods get AWS permissions through EKS Pod Identity instead (see ebs_csi_pod_identity).
  enable_irsa = false

  addons = {
    vpc-cni                = { before_compute = true }
    kube-proxy             = {}
    coredns                = {}
    eks-pod-identity-agent = { before_compute = true }
    metrics-server         = {} # needed by the Helm chart's HPA
    aws-ebs-csi-driver = {      # needed by the Postgres PVC
      pod_identity_association = [{
        role_arn        = module.ebs_csi_pod_identity.iam_role_arn
        service_account = "ebs-csi-controller-sa"
      }]
    }
  }

  eks_managed_node_groups = {
    main = {
      # free-plan eligible type; 2 nodes x 2 vCPU stays within the 5 vCPU quota
      instance_types = ["m7i-flex.large"]
      min_size       = 2
      max_size       = 2
      desired_size   = 2
    }
  }
}

# IAM role for the AWS Load Balancer Controller, which turns Ingress resources into ALBs
module "lb_controller_pod_identity" {
  source                          = "terraform-aws-modules/eks-pod-identity/aws"
  version                         = "2.9.0"
  name                            = "${var.cluster_name}-lb-controller"
  attach_aws_lb_controller_policy = true

  associations = {
    controller = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }
}

# IAM role the EBS CSI driver assumes (via EKS Pod Identity) to create and attach EBS volumes
module "ebs_csi_pod_identity" {
  source                    = "terraform-aws-modules/eks-pod-identity/aws"
  version                   = "2.9.0"
  name                      = "${var.cluster_name}-ebs-csi"
  attach_aws_ebs_csi_policy = true
}
