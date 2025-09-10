replace "this" with the resource names below
aws_vpc - vpc
 2. aws_subnet - public and privateSubnet
 3. aws_internet_gateway - igw
 4. aws_route_table - publicRT and privateRT
 5. aws_route_table_association - PublicSubnetAssoc and PrivateSubnetAssoc
 5. aws_route - PublicRoute and PrivateRoute

# Breakdown of subnet block
resource "aws_subnet" "this" {
  for_each = toset(var.azs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.cidr, 8, index(var.azs, each.value))
  availability_zone = each.value

  tags = merge(var.tags, { Name = "${var.name}-subnet-${each.value}" })
}


 The aws_subnet resource block with for_each = toset(var.azs) does create multiple subnets. Here's how:

for_each is a meta-argument that creates multiple instances of a resource
var.azs is expected to be a list of availability zones
toset() converts the list to a set, which is required by for_each
One subnet will be created for each AZ in the list
The CIDR block calculation:

cidrsubnet(var.cidr, 8, index(var.azs, each.value)) breaks down as:
var.cidr is the VPC's CIDR block (e.g., "10.0.0.0/16")
8 means we're creating subnets with an additional 8 bits of network prefix
index(var.azs, each.value) gets the position of current AZ in the list, used as the subnet number
Example:

If VPC CIDR is "10.0.0.0/16" and azs = ["us-east-1a", "us-east-1b"]
First subnet (index 0): cidrsubnet("10.0.0.0/16", 8, 0) = "10.0.0.0/24"
Second subnet (index 1): cidrsubnet("10.0.0.0/16", 8, 1) = "10.0.1.0/24"
So if var.azs = ["us-east-1a", "us-east-1b"], this will create two subnets, one in each AZ, with automatically calculated CIDR blocks.

🔹 Option 1: One NAT Gateway per VPC (cheaper, less resilient)

You create a single NAT Gateway in one AZ’s public subnet.

All private subnets route traffic to it (even across AZs).

Pros: Simple, cost-effective (~$32/month per NAT Gateway + data transfer).

Cons: If that AZ goes down, private subnets in other AZs lose outbound internet access (patches, updates, external API calls).

🔹 Option 2: One NAT Gateway per AZ (recommended best practice for production)

You create a NAT Gateway in every AZ that has private subnets.

Each private subnet routes outbound traffic to its NAT Gateway in the same AZ.

Pros: High availability — no single AZ failure can break outbound internet access.

Cons: More expensive (multiplies cost by number of AZs).

✅ AWS Best Practice

AWS recommends one NAT Gateway per AZ if:

You’re in production or running critical workloads.

You require high availability across AZs.

You can tolerate the higher cost.

For dev/test environments, most teams use one NAT Gateway per VPC to save cost.

👉 So, if you’re designing this multi-VPC / multi-region TGW setup as a foundation for enterprise prod workloads, I’d suggest:

Production → NAT Gateway per AZ (best practice).

Dev/Test → NAT Gateway per VPC (cost saving).

# worked but can be modified for tgw to always have subnets
output "vpc_ids" {
  value       = { for k, _ in var.vpcs : k => aws_vpc.vpc[k].id }
  description = "VPC ID per key"
}

output "public_subnet_ids" {
  value       = { for k, _ in var.vpcs : k => try([for s in aws_subnet.public_subnet[k]  : s.id], []) }
  description = "Public subnet IDs per VPC"
}

output "private_subnet_ids" {
  value = {
    for vpc_name, vpc in var.vpcs :
    vpc_name => [for k, s in aws_subnet.private_subnet : s.id if startswith(k, vpc_name)]
  }
}

output "public_route_table_ids" {
  value       = { for k, _ in var.vpcs : k => [aws_route_table.public_rtbl[k].id] }
  description = "Public RT IDs per VPC"
}

output "private_route_table_ids" {
  value       = { for k, _ in var.vpcs : k => [aws_route_table.private_rtbl[k].id] }
  description = "Private RT IDs per VPC"
}





We’ll make your outputs.tf in the VPC module structured so that every VPC returns:

vpc_ids → { vpc1 = "vpc-xxxx", vpc2 = "vpc-yyyy" }

public_subnet_ids → { vpc1 = ["subnet-a","subnet-b"], vpc2 = ["subnet-c","subnet-d"] }

private_subnet_ids → { vpc1 = ["subnet-x","subnet-y"], vpc2 = ["subnet-z","subnet-w"] }

✅ Updated outputs.tf for your VPC module
# VPC IDs (map by name)
output "vpc_ids" {
  value = {
    for vpc_name, vpc in aws_vpc.vpc :
    vpc_name => vpc.id
  }
}

# Public Subnet IDs (grouped per VPC)
output "public_subnet_ids" {
  value = {
    for vpc_name, vpc in var.vpcs :
    vpc_name => [
      for k, s in aws_subnet.public_subnet :
      s.id if startswith(k, "${vpc_name}-public")
    ]
  }
}

# Private Subnet IDs (grouped per VPC)
output "private_subnet_ids" {
  value = {
    for vpc_name, vpc in var.vpcs :
    vpc_name => [
      for k, s in aws_subnet.private_subnet :
      s.id if startswith(k, "${vpc_name}-private")
    ]
  }
}

🔗 Example usage in TGW module call
attachments = {
  vpc1 = {
    vpc_id         = module.ohio_vpcs.vpc_ids["vpc1"]
    subnet_ids     = module.ohio_vpcs.private_subnet_ids["vpc1"]  # ✅ now a list
    associate_with = "prod"
    propagate_to   = "prod"
  }
  vpc2 = {
    vpc_id         = module.ohio_vpcs.vpc_ids["vpc2"]
    subnet_ids     = module.ohio_vpcs.private_subnet_ids["vpc2"]
    associate_with = "prod"
    propagate_to   = "prod"
  }
}


👉 That guarantees non-empty subnet lists, so TGW VPC attachments won’t fail.

Do you want me to also refactor your main.tf in the VPC module slightly so that the subnet naming convention (${vpc_name}-public, ${vpc_name}-private) is enforced automatically via tags? That way the outputs won’t break if someone misnames a subnet.

# Create VPCs
resource "aws_vpc" "vpc" {
  for_each = var.vpcs

  cidr_block           = each.value.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = each.key
  })
}

resource "aws_internet_gateway" "multi_igw" {
  for_each = aws_vpc.vpc

  vpc_id = each.value.id

  tags = merge(var.tags, {
    Name = "${each.key}-igw"
  })
}

# Public subnets (loop inside each VPC)
# Public subnets (multi per VPC, count = subnet_count)
resource "aws_subnet" "public_subnet" {
  for_each = {
    for vpc_name, vpc in var.vpcs :
    vpc_name => {
      vpc_id        = aws_vpc.vpc[vpc_name].id
      cidr          = vpc.public_subnet_cidrs
      azs           = vpc.azs
    }
  }

  count = length(each.value.cidr)

  vpc_id                  = each.value.vpc_id
  cidr_block              = each.value.cidr[count.index]
  availability_zone       = each.value.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${each.key}-public-${count.index + 1}"
    Tier = "Public"
  })
}

# Private subnets
resource "aws_subnet" "private_subnet" {
  for_each = {
    for vpc_name, vpc in var.vpcs :
    vpc_name => {
      vpc_id        = aws_vpc.vpc[vpc_name].id
      cidr          = vpc.private_subnet_cidrs
      azs           = vpc.azs
    }
  }

  count = length(each.value.cidr)

  vpc_id            = each.value.vpc_id
  cidr_block        = each.value.cidr[count.index]
  availability_zone = each.value.azs[count.index]

  tags = merge(var.tags, {
    Name = "${each.key}-private-${count.index + 1}"
    Tier = "Private"
  })
}

# Route tables
resource "aws_route_table" "public_rtbl" {
  for_each = aws_vpc.vpc

  vpc_id = each.value.id

  tags = merge(var.tags, {
    Name = "${each.key}-public-rt"
  })
}

resource "aws_route_table" "private_rtbl" {
  for_each = aws_vpc.vpc

  vpc_id = each.value.id

  tags = merge(var.tags, {
    Name = "${each.key}-private-rt"
  })
}

# Associations
# Public route table associations
resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public_subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rtbl[each.key].id
}


# Private route table associations
resource "aws_route_table_association" "private_assoc" {
  for_each = aws_subnet.private_subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rtbl[each.key].id
}


# Routes
resource "aws_route" "public_rt" {
  for_each = aws_route_table.public_rtbl

  route_table_id         = each.value.id
  destination_cidr_block = var.public_rt_destination_cidr_block
  gateway_id             = aws_internet_gateway.multi_igw[replace(each.key, "-public-rt", "")].id
}

# # Elastic IPs for NAT (one per public subnet / AZ)
# Elastic IPs for NAT (one per AZ per VPC)
resource "aws_eip" "nat" {
  for_each = {
    for vpc_name, vpc in var.vpcs :
    vpc_name => { azs = vpc.azs }
  }

  count = length(each.value.azs)

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${each.key}-nat-eip-${count.index + 1}"
  })
}

# NAT Gateways (per AZ)
resource "aws_nat_gateway" "ngw" {
  for_each = {
    for vpc_name, vpc in var.vpcs :
    vpc_name => {
      pub_subnets = [
        for s in aws_subnet.public_subnet :
        s.id if startswith(s.tags["Name"], "${vpc_name}-public")
      ]
    }
  }

  count = length(each.value.pub_subnets)

  allocation_id = aws_eip.nat[each.key][count.index].id
  subnet_id     = each.value.pub_subnets[count.index]

  tags = merge(var.tags, {
    Name = "${each.key}-ngw-${count.index + 1}"
  })
}

# Private route tables (one per VPC private subnet)
resource "aws_route_table" "private_rtbl" {
  for_each = aws_subnet.private_subnet

  vpc_id = each.value.vpc_id

  tags = merge(var.tags, {
    Name = "${each.key}-rt"
  })
}


# Routes: each private subnet → its AZ NAT GW
resource "aws_route" "private_rt" {
  for_each = aws_subnet.private_subnet

  route_table_id         = aws_route_table.private_rtbl[each.key].id
  destination_cidr_block = var.private_rt_destination_cidr_block
  nat_gateway_id         = aws_nat_gateway.ngw[replace(each.key, "-private", "-public")].id
}
