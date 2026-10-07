variable "name" {
  description = "Name prefix for every resource (e.g. taskboard-dev)."
  type        = string
}

variable "tags" {
  description = "Extra tags merged onto every resource."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------- network ---
variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across (at least 2 for EKS)."
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2
    error_message = "EKS needs subnets in at least two availability zones."
  }
}

variable "public_subnet_cidrs" {
  description = "One public subnet CIDR per AZ (load balancers, NAT gateway)."
  type        = list(string)
  default     = ["10.20.101.0/24", "10.20.102.0/24"]
}

variable "private_subnet_cidrs" {
  description = "One private subnet CIDR per AZ (EKS worker nodes)."
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "enable_nat_gateway" {
  description = "Create a (single) NAT gateway so private nodes can reach the internet (~USD 32/month + data)."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Ship VPC flow logs to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Retention for CloudWatch log groups (flow logs, EKS control plane)."
  type        = number
  default     = 365
}

# -------------------------------------------------------------------- EKS ---
variable "enable_eks" {
  description = "Create the EKS control plane. Set false to provision only network + ECR."
  type        = bool
  default     = true
}

variable "enable_node_group" {
  description = "Create the EKS managed node group (needs enable_eks = true)."
  type        = bool
  default     = true
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.31"
}

variable "cluster_endpoint_public_access" {
  description = "Expose the EKS API endpoint publicly (restricted by cluster_endpoint_public_access_cidrs)."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint. Narrow this to your own IP."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 4
}

variable "node_disk_size" {
  description = "Root volume size (GiB) of each worker node."
  type        = number
  default     = 30
}

# -------------------------------------------------------------------- ECR ---
variable "ecr_repositories" {
  description = "ECR repositories to create (alternative to GHCR)."
  type        = list(string)
  default     = ["taskboard-backend", "taskboard-frontend"]
}

variable "ecr_keep_last_images" {
  description = "Lifecycle policy: number of images kept per repository."
  type        = number
  default     = 20
}
