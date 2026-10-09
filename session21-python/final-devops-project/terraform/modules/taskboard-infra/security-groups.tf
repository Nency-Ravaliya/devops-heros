# ---------------------------------------------------------------------------
# Additional security groups. EKS also creates its own "cluster security
# group"; these SGs make the control-plane <-> node traffic explicit.
# ---------------------------------------------------------------------------
resource "aws_security_group" "cluster" {
  name        = "${local.cluster_name}-cluster-sg"
  description = "EKS control plane additional security group"
  vpc_id      = aws_vpc.this.id
  tags        = merge(local.tags, { Name = "${local.cluster_name}-cluster-sg" })
}

resource "aws_security_group" "nodes" {
  name        = "${local.cluster_name}-node-sg"
  description = "EKS worker nodes"
  vpc_id      = aws_vpc.this.id

  tags = merge(local.tags, {
    Name                                          = "${local.cluster_name}-node-sg"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  })
}

# Nodes -> API server (kubelet, pods calling the Kubernetes API)
resource "aws_vpc_security_group_ingress_rule" "cluster_from_nodes_https" {
  security_group_id            = aws_security_group.cluster.id
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "Nodes to EKS API"
}

# API server -> kubelet / webhooks on the nodes
resource "aws_vpc_security_group_egress_rule" "cluster_to_nodes" {
  security_group_id            = aws_security_group.cluster.id
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 1025
  to_port                      = 65535
  description                  = "EKS API to kubelet and webhooks"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_cluster" {
  #checkov:skip=CKV_AWS_25:Source is the EKS control-plane SG, not 0.0.0.0/0 (false positive on the port range)
  security_group_id            = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.cluster.id
  ip_protocol                  = "tcp"
  from_port                    = 1025
  to_port                      = 65535
  description                  = "EKS API to kubelet and webhooks"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_cluster_https" {
  security_group_id            = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.cluster.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "EKS API to admission webhooks on 443"
}

# Node <-> node (pod-to-pod traffic, CoreDNS, etc.)
resource "aws_vpc_security_group_ingress_rule" "nodes_self" {
  security_group_id            = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "-1"
  description                  = "Node to node (all protocols)"
}

# Nodes need outbound access (ECR/GHCR pulls, AWS APIs) via the NAT gateway.
resource "aws_vpc_security_group_egress_rule" "nodes_all" {
  #checkov:skip=CKV_AWS_382:Worker nodes must pull images and call AWS APIs via NAT
  security_group_id = aws_security_group.nodes.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Outbound internet via NAT"
}
