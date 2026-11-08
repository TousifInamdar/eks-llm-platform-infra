terraform {
  required_version = ">= 1.11"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}

provider "aws" {
  region = "ap-southeast-2"
  default_tags {
    tags = { Project = "eks-llm-platform", Owner = "tousif", ManagedBy = "terraform" }
  }
}

variable "state_bucket_name" {
  type    = string
  default = "tousif-eks-llm-tfstate-2026" # must be globally unique. Change it if apply says it's taken
}

resource "aws_s3_bucket" "tfstate" {
  bucket = var.state_bucket_name
  lifecycle { prevent_destroy = true } # a nightly destroy can never delete your state
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "state_bucket" { value = aws_s3_bucket.tfstate.bucket }