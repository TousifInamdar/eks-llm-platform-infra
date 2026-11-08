# No `profile` here: credentials come from AWS_PROFILE=llm-lab, so the code runs unchanged in CI (OIDC).
provider "aws" {
  region = var.region

  # Stamped on every resource the provider creates: cost tracking in Cost Explorer + ownership.
  default_tags {
    tags = {
      Project     = var.project
      Owner       = "tousif"
      ManagedBy   = "terraform"
      Environment = "dev"
    }
  }
}
