module "vpc" {
  source = "../../modules/vpc"

  name            = var.project
  cidr            = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  nat_az          = var.nat_az
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  subnet_ids         = module.vpc.private_subnet_ids
  admin_cidr         = var.admin_cidr
}
