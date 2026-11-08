module "vpc" {
  source = "../../modules/vpc"

  name            = var.project
  cidr            = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  nat_az          = var.nat_az
}

# EKS (terraform-aws-modules/eks/aws, pinned) goes here in Block B.
