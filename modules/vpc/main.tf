 
# VPC
# -------------------
resource "aws_vpc" "vpc" {
  for_each = var.vpcs

  cidr_block           = each.value.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = each.key
  }
}

# -------------------
# Public Subnets
# -------------------
resource "aws_subnet" "public_subnet" {
  for_each = {
    for pair in flatten([
      for vpc_name, vpc in var.vpcs : [
        for idx, az in vpc.azs : {
          key      = "${vpc_name}-${az}-public"
          vpc_name = vpc_name
          az       = az
          cidr     = vpc.public_subnet_cidrs[idx]
        }
      ]
    ]) : pair.key => pair
  }

  vpc_id            = aws_vpc.vpc[each.value.vpc_name].id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr

  tags = {
    Name = "${each.value.vpc_name}-public-${each.value.az}"
  }
}

resource "aws_subnet" "private_subnet" {
  for_each = {
    for pair in flatten([
      for vpc_name, vpc in var.vpcs : [
        for idx, az in vpc.azs : {
          key      = "${vpc_name}-${az}-private"
          vpc_name = vpc_name
          az       = az
          cidr     = vpc.private_subnet_cidrs[idx]
        }
      ]
    ]) : pair.key => pair
  }

  vpc_id            = aws_vpc.vpc[each.value.vpc_name].id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr

  tags = {
    Name = "${each.value.vpc_name}-private-${each.value.az}"
  }
}

# -------------------
# Internet Gateway
# -------------------
resource "aws_internet_gateway" "igw" {
  for_each = aws_vpc.vpc

  vpc_id = each.value.id

  tags = {
    Name = "${each.key}-igw"
  }
}

# -------------------
# Elastic IPs for NAT
# -------------------
# resource "aws_eip" "nat" {
#   for_each = {
#     for pair in flatten([
#       for vpc_name, vpc in var.vpcs : [
#         for idx, az in vpc.azs : {
#           key      = "${vpc_name}-${az}-public"
#           vpc_name = vpc_name
#           az       = az
#         }
#       ]
#     ]) : pair.key => pair
#   }

  

#   tags = {
#     Name = "${each.value.vpc_name}-eip-${each.value.az}"
#   }
# }

# # -------------------
# # NAT Gateways
# # -------------------
# resource "aws_nat_gateway" "ngw" {
#   for_each = {
#     for pair in flatten([
#       for vpc_name, vpc in var.vpcs : [
#         for idx, az in vpc.azs : {
#           key      = "${vpc_name}-${az}-public"
#           vpc_name = vpc_name
#           az       = az
#         }
#       ]
#     ]) : pair.key => pair
#   }

#   allocation_id = aws_eip.nat[each.key].id
#   subnet_id     = aws_subnet.public_subnet[each.key].id

#   tags = {
#     Name = "${each.value.vpc_name}-nat-${each.value.az}"
#   }
# }

# -------------------
# Route Tables
# -------------------
resource "aws_route_table" "public_rtbl" {
  for_each = aws_vpc.vpc

  vpc_id = each.value.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[each.key].id
  }

  tags = {
    Name = "${each.key}-public-rt"
  }
}

resource "aws_route_table" "private_rtbl" {
  for_each = aws_vpc.vpc

  vpc_id = each.value.id

  # route {
  #   cidr_block     = "0.0.0.0/0"
  #   nat_gateway_id = values(aws_nat_gateway.ngw)[0].id # first NAT per VPC
  # }

  tags = {
    Name = "${each.key}-private-rt"
  }
}

# -------------------
# Route Table Associations
# -------------------
resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public_subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rtbl[split("-", each.key)[0]].id
}

resource "aws_route_table_association" "private_assoc" {
  for_each = aws_subnet.private_subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rtbl[split("-", each.key)[0]].id
}
