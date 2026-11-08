terraform {
  required_version = ">= 1.11" # 1.11+ needed for use_lockfile (S3-native locking) in backend.tf
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" } # root pins the major; modules only set a minimum
  }
}
