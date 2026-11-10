resource "aws_iam_policy" "lbc" {
  name   = "${aws_eks_cluster.main.name}-AWSLoadBalancerController"
  policy = file("${path.module}/policies/lbc_iam_policy.json")
}

resource "aws_iam_role" "lbc" {
  name               = "${aws_eks_cluster.main.name}-lbc"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume.json
}

resource "aws_iam_role_policy_attachment" "lbc" {
  role       = aws_iam_role.lbc.name
  policy_arn = aws_iam_policy.lbc.arn
}

resource "aws_eks_pod_identity_association" "lbc" {
  cluster_name    = aws_eks_cluster.main.name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.lbc.arn
}