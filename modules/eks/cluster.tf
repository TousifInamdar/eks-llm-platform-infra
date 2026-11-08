# ---------- 2. The control plane (AWS-managed API server + etcd) ----------
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.subnet_ids   # control-plane ENIs land here
    endpoint_private_access = true             # nodes reach the API inside the VPC
    endpoint_public_access  = true             # kubectl from my laptop...
    public_access_cidrs     = [var.admin_cidr] # ...but only from my IP
  }

  access_config {
    authentication_mode                         = "API" # access entries only, no aws-auth ConfigMap
    bootstrap_cluster_creator_admin_permissions = true  # whoever runs apply (tousif-admin) gets cluster-admin
  }

  # Don't let EKS install unmanaged vpc-cni/kube-proxy/coredns. We install them as managed add-ons
  # (addons.tf), so Terraform owns their versions. Changing this later forces a new cluster.
  bootstrap_self_managed_addons = false

  # Destroyed every night.
  deletion_protection = false

  # Lab: no control-plane logs. Production: enabled_cluster_log_types = ["api", "audit", "authenticator"]
  # into a CloudWatch log group with retention; audit logs answer "who did what to the cluster".
  enabled_cluster_log_types = []

  # Lab: no encryption_config block = secrets in etcd use AWS-owned keys only. Production: envelope-encrypt
  # Kubernetes secrets with a customer-managed KMS key (encryption_config { resources = ["secrets"] ... }).

  # The cluster role's policy must exist before EKS uses it, and must outlive the cluster on destroy,
  # otherwise EKS can't clean up the ENIs it created.
  depends_on = [aws_iam_role_policy_attachment.cluster]
}
