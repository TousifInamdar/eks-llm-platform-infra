terraform {
  required_version = ">= 1.11"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 6.0" } # module sets a floor; the root (envs/dev) pins ~> 6.0
  }
}
