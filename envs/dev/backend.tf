terraform {
  backend "s3" {
    bucket       = "tousif-eks-llm-tfstate-2026"
    key          = "dev/terraform.tfstate"
    region       = "ap-southeast-2"
    encrypt      = true
    use_lockfile = true # S3-native state locking, no DynamoDB table needed
  }
}