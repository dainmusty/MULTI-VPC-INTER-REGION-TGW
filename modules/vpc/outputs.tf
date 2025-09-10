output "vpc_ids" {
  value = {
    for vpc_name, vpc in var.vpcs :
    vpc_name => aws_vpc.vpc[vpc_name].id
  }
}

output "public_subnet_ids" {
  value = {
    for vpc_name, vpc in var.vpcs :
    vpc_name => [
      for az in vpc.azs :
      aws_subnet.public_subnet["${vpc_name}-${az}-public"].id
    ]
  }
}

output "private_subnet_ids" {
  value = {
    for vpc_name, vpc in var.vpcs :
    vpc_name => [
      for az in vpc.azs :
      aws_subnet.private_subnet["${vpc_name}-${az}-private"].id
    ]
  }
}


output "vpc_cidrs" {
  description = "CIDR blocks for all VPCs created in the vpc module"
  value       = { for k, v in aws_vpc.vpc : k => v.cidr_block }
}
