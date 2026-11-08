# No addon_version: EKS installs its default version for this Kubernetes version.
# OVERWRITE on create: if something already exists with the same name, the managed add-on wins.

# ---------- 4. BEFORE nodes: DaemonSets the nodes need the moment they boot ----------
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "vpc-cni" # gives every pod a real VPC IP (uses the node role's CNI policy)
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "eks-pod-identity-agent" # hands out IAM credentials to pods with an association
  resolve_conflicts_on_create = "OVERWRITE"
}

# ---------- 6. AFTER nodes ----------
resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy" # programs iptables so ClusterIP Services work
  resolve_conflicts_on_create = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.default]
}

# coredns is a Deployment: with no nodes its pods stay Pending and the add-on never reports ACTIVE.
resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.default]
}

# ---------- 8. EBS CSI driver, with its own IAM role through Pod Identity ----------
resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_create = "OVERWRITE"

  # EKS creates the Pod Identity association: SA kube-system/ebs-csi-controller-sa -> ebs_csi role.
  pod_identity_association {
    role_arn        = aws_iam_role.ebs_csi.arn
    service_account = "ebs-csi-controller-sa"
  }

  # Found on first apply: created in parallel with kube-proxy/coredns, the controller's startup health
  # check (DNS lookup of the EC2 endpoint via the kube-dns ClusterIP) failed and its sidecars restarted
  # 8 times until DNS came up. Waiting for kube-proxy (ClusterIP routing) + coredns (DNS) avoids that.
  depends_on = [
    aws_eks_node_group.default,             # controller is a Deployment, needs nodes
    aws_eks_addon.kube_proxy,               # Service ClusterIPs (incl. kube-dns 172.20.0.10) must route
    aws_eks_addon.coredns,                  # DNS must answer before the driver resolves the EC2 endpoint
    aws_iam_role_policy_attachment.ebs_csi, # role must have its policy before the driver uses it
  ]
}
