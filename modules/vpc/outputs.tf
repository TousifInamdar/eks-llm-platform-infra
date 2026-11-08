output "vpc_id" {
  description = "ID of the VPC (the EKS module needs it)"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# values() on a map is ordered by key (the AZ name), so these lists are stable between plans.
output "public_subnet_ids" {
  description = "Public subnet IDs, one per AZ (ALB, NAT)"
  value       = [for az, s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs, one per AZ (EKS nodes and pods)"
  value       = [for az, s in aws_subnet.private : s.id]
}

output "nat_public_ip" {
  description = "Public IP that all outbound traffic from the private subnets comes from"
  value       = aws_eip.nat.public_ip
}

output "azs" {
  description = "AZs the VPC spans"
  value       = keys(var.private_subnets)
}
