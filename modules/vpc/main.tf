# ---------- VPC ----------
resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  enable_dns_support   = true # the VPC's built-in DNS resolver
  enable_dns_hostnames = true # EKS nodes need private DNS hostnames to register with the cluster
  tags                 = merge(var.tags, { Name = var.name })
}

# Best practice (CIS benchmark): the default security group allows all traffic between its members.
# Taking control of it with no rules locks it down. EKS creates its own security groups.
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.name}-default-sg-locked" })
}

# ---------- Internet gateway: the VPC's door to the internet ----------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.name}-igw" })
}

# ---------- Subnets: in AWS every subnet lives in exactly ONE AZ (unlike GCP, where subnets are regional) ----------
resource "aws_subnet" "public" {
  for_each                = var.public_subnets # key = AZ, value = CIDR
  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name                     = "${var.name}-public-${each.key}"
    "kubernetes.io/role/elb" = "1" # tells the AWS Load Balancer Controller: internet-facing LBs go here
  })
}

resource "aws_subnet" "private" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = each.value
  tags = merge(var.tags, {
    Name                              = "${var.name}-private-${each.key}"
    "kubernetes.io/role/internal-elb" = "1" # internal LBs go here
  })
}

# ---------- NAT: lets private nodes reach the internet (image pulls, model downloads) without being reachable ----------
resource "aws_eip" "nat" {
  domain     = "vpc"
  tags       = merge(var.tags, { Name = "${var.name}-nat-eip" })
  depends_on = [aws_internet_gateway.igw] # a public IP is useless until the VPC has an internet gateway
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[var.nat_az].id # a NAT gateway must sit in a PUBLIC subnet
  tags          = merge(var.tags, { Name = "${var.name}-nat-${var.nat_az}" })
  depends_on    = [aws_internet_gateway.igw]
}

# ---------- Route tables: THIS is what makes a subnet public or private ----------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id # public = default route goes to the IGW
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.name}-private-rt" })
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id # private = default route goes to the NAT
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}