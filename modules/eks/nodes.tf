# ---------- 5. Managed node group: EKS creates the launch template + Auto Scaling group for us ----------
# No custom launch template: EKS picks the AL2023 AMI, attaches the cluster security group, and writes
# the nodeadm bootstrap config. Less to own, but no custom user data or extra security groups.
resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "default"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids # private subnets only

  ami_type       = "AL2023_x86_64_STANDARD"
  instance_types = var.node_instance_types
  capacity_type  = "ON_DEMAND"
  disk_size      = var.node_disk_size # only allowed without a custom launch template

  scaling_config {
    min_size     = var.node_count
    max_size     = var.node_count
    desired_size = var.node_count
  }

  update_config {
    max_unavailable = 1 # rolling AMI/version updates replace one node at a time
  }

  # Order matters:
  # - node policies: without them the kubelet can't join, and on destroy EC2 can't clean up ENIs.
  # - vpc-cni: without it nodes never become Ready (no pod networking).
  # - pod-identity agent: must be running before any pod (e.g. EBS CSI) asks for credentials.
  depends_on = [
    aws_iam_role_policy_attachment.node,
    aws_eks_addon.vpc_cni,
    aws_eks_addon.pod_identity_agent,
  ]
}
