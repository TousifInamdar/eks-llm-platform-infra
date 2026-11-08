variable "region" {
  description = "AWS region. The free-plan SCPs deny every region except Sydney."
  type        = string
  default     = "ap-southeast-2"

  validation {
    condition     = var.region == "ap-southeast-2"
    error_message = "Only ap-southeast-2 is allowed on this account (SCP explicit deny elsewhere)."
  }
}

variable "project" {
  description = "Project name, used as the resource name prefix and the Project tag"
  type        = string
  default     = "eks-llm-platform"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "AZ => CIDR for public subnets (ALB, NAT)"
  type        = map(string)
  default = {
    "ap-southeast-2a" = "10.0.0.0/24"
    "ap-southeast-2b" = "10.0.1.0/24"
  }
}

variable "private_subnets" {
  description = "AZ => CIDR for private subnets. /20 = 4091 usable IPs each, because VPC CNI gives every pod a VPC IP."
  type        = map(string)
  default = {
    "ap-southeast-2a" = "10.0.16.0/20"
    "ap-southeast-2b" = "10.0.32.0/20"
  }
}

variable "nat_az" {
  description = "AZ for the single NAT gateway"
  type        = string
  default     = "ap-southeast-2a"
}
