variable "name" {
  description = "Prefix for every resource's Name tag"
  type        = string
}

variable "cidr" {
  description = "VPC CIDR block"
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr, 0))
    error_message = "cidr must be a valid IPv4 CIDR, e.g. 10.0.0.0/16."
  }
}

variable "public_subnets" {
  description = "Map of AZ => CIDR for public subnets (load balancers, NAT)"
  type        = map(string)
}

variable "private_subnets" {
  description = "Map of AZ => CIDR for private subnets (EKS nodes and pods)"
  type        = map(string)
}

variable "nat_az" {
  description = "AZ that hosts the single NAT gateway (cost trade-off: prod uses one per AZ)"
  type        = string

  # Checked here (Terraform >= 1.9 allows referencing other variables) rather than as a
  # precondition on the NAT gateway: an unknown key would fail on aws_subnet.public[var.nat_az]
  # with a confusing "Invalid index" error before a precondition ever runs.
  validation {
    condition     = contains(keys(var.public_subnets), var.nat_az)
    error_message = "nat_az must be one of the AZs in public_subnets."
  }
}

variable "tags" {
  description = "Extra tags merged onto every resource"
  type        = map(string)
  default     = {}
}