variable "cluster_name" {
  description = "EKS cluster name, also the prefix for IAM role names"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes <major>.<minor>, e.g. 1.37. Use a version in EKS standard support (extended support costs 6x)."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the control-plane ENIs and the nodes (at least 2 AZs)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "EKS needs subnets in at least two AZs."
  }
}

variable "admin_cidr" {
  description = "The only CIDR allowed to reach the public API endpoint (x.x.x.x/32)"
  type        = string

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0)) && var.admin_cidr != "0.0.0.0/0"
    error_message = "admin_cidr must be a valid CIDR and must not be 0.0.0.0/0."
  }
}

variable "node_instance_types" {
  description = "Instance types for the managed node group"
  type        = list(string)
  default     = ["m7i-flex.large"]
}

variable "node_disk_size" {
  description = "Root EBS volume size (GiB) per node. Model images + Ollama layers need more than the 20 GiB default."
  type        = number
  default     = 30
}

variable "node_count" {
  description = "Fixed node count (min = max = desired)"
  type        = number
  default     = 2
}
