Absolutely—set up a clean, production-ready Terraform baseline for a multi-region Transit Gateway already on your canvas. It includes:

TGWs in two regions (A & B)

Inter-region TGW peering + accepter

VPC attachments for any number of existing VPCs (you just pass VPC IDs, TGW subnet IDs, and VPC route table IDs)

TGW route tables, associations, propagations

VPC route updates toward remote-region CIDRs

You’ll find a full, file-by-file project (providers.tf, variables.tf, main.tf, attachments.tf, routes.tf, outputs.tf, and a sample terraform.tfvars) ready to terraform init/plan/apply.

If you’re doing multi-account with AWS RAM, there’s a short section outlining what to add; I can expand that into runnable code if you want.


output "tgw_a_id" {
value = aws_ec2_transit_gateway.tgw_ohio.id
}


output "tgw_b_id" {
value = aws_ec2_transit_gateway.tgw_virginia.id
}


output "tgw_a_route_table_id" {
value = aws_ec2_transit_gateway_route_table.rt_ohio.id
}


output "tgw_b_route_table_id" {
value = aws_ec2_transit_gateway_route_table.rt_virginia.id
}

# didnt work, will investigate later
# resource "aws_route" "virginia_to_ohio" {
# provider = aws.virginia
# for_each = { for x in local.vpc_rt_to_ohio : "${x.rt}|${x.cidr}" => x }
# route_table_id = each.value.rt
# destination_cidr_block = each.value.cidr
# transit_gateway_id = aws_ec2_transit_gateway.tgw_virginia.id
# }

# resource "aws_route" "ohio_to_virginia" {
# provider = aws.ohio
# for_each = { for x in local.vpc_rt_to_virginia : "${x.rt}|${x.cidr}" => x }
# route_table_id = each.value.rt
# destination_cidr_block = each.value.cidr
# transit_gateway_id = aws_ec2_transit_gateway.tgw_ohio.id
# }



# Inter-Region Peering Attachment (A -> B) and Accepter (B)
resource "aws_ec2_transit_gateway_peering_attachment" "ohio_to_virginia" {
provider = aws.ohio
transit_gateway_id = aws_ec2_transit_gateway.tgw_ohio.id
peer_transit_gateway_id = aws_ec2_transit_gateway.tgw_virginia.id
peer_account_id = data.aws_caller_identity.current.account_id
peer_region = var.region_virginia


tags = merge(var.tags, {
Name = "${var.project}-tgw-peer-${var.region_ohio}-to-${var.region_virginia}"
})
}


resource "aws_ec2_transit_gateway_peering_attachment_accepter" "virginia_accepts" {
provider = aws.virginia
transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.ohio_to_virginia.id


tags = merge(var.tags, {
Name = "${var.project}-tgw-peer-${var.region_virginia}-accept"
})
}


# TGW Route Tables (one per region) + associations/propagations will be in routes.tf
resource "aws_ec2_transit_gateway_route_table" "ohio_tgw_rt" {
provider = aws.ohio
transit_gateway_id = aws_ec2_transit_gateway.tgw_ohio.id
tags = merge(var.tags, { Name = "${var.project}-tgw-rt-${var.region_ohio}" })
}


resource "aws_ec2_transit_gateway_route_table" "virginia_tgw_rt" {
provider = aws.virginia
transit_gateway_id = aws_ec2_transit_gateway.tgw_virginia.id
tags = merge(var.tags, { Name = "${var.project}-tgw-rt-${var.region_virginia}" })
}


resource "aws_ec2_transit_gateway" "ohio" {
  provider                         = aws.var.region
  description                      = "${var.project}-tgw-${var.region_1}"
  amazon_side_asn                  = var.asn
  default_route_table_association  = "disable"
  default_route_table_propagation  = "disable"
  dns_support                      = "enable"
  vpn_ecmp_support                 = "enable"
  tags = merge(var.tags, { Name = "${var.project}-tgw-${var.region_1}" })
}


resource "aws_ec2_transit_gateway" "virginia" {
  provider                         = aws.var.region
  description                      = "${var.project}-tgw-${var.region_2}"
  amazon_side_asn                  = var.asn
  default_route_table_association  = "disable"
  default_route_table_propagation  = "disable"
  dns_support                      = "enable"
  vpn_ecmp_support                 = "enable"
  tags = merge(var.tags, { Name = "${var.project}-tgw-${var.region_2}" })
}


# Ohio: attach vpc1..3
resource "aws_ec2_transit_gateway_vpc_attachment" "ohio" {
  provider            = aws.var.region_1
  for_each            = var.ohio_vpc_attachments  # map of {vpc_id, subnet_ids, route_table_ids}
  transit_gateway_id  = module.tgw.tgw_ohio_ids
  vpc_id              = each.value.vpc_id
  subnet_ids          = each.value.subnet_ids
  dns_support         = "enable"
  ipv6_support        = "disable"
  tags = { Name = "ohio-${each.key}-attach" }
}

# Virginia: attach vpc1..3
resource "aws_ec2_transit_gateway_vpc_attachment" "virginia" {
  provider            = aws.var.region_2
  for_each            = var.virginia_vpc_attachments
  transit_gateway_id  = module.tgw_hub.tgw_ids.us_east_1
  vpc_id              = each.value.vpc_id
  subnet_ids          = each.value.subnet_ids
  dns_support         = "enable"
  ipv6_support        = "disable"
  tags = { Name = "virginia-${each.key}-attach" }
}

# If attachments come from a different (spoke) account
# # In each spoke account per region:
# resource "aws_ram_resource_share_accepter" "ohio" {
#   provider             = aws.ohio
#   share_arn            = var.ohio_share_arn   # provided by hub (output)
# }

# data "aws_ec2_transit_gateway" "ohio_shared" {
#   provider = aws.ohio
#   filter {
#     name   = "transit-gateway-id"
#     values = [var.ohio_tgw_id]                # pass from hub output, or find by tag
#   }
# }

# # Then create aws_ec2_transit_gateway_vpc_attachment pointing to data.aws_ec2_transit_gateway.ohio_shared.id


RAM shares operate at the TGW resource level, not per VPC. You share a TGW with AWS accounts or your AWS Organization. Those principals then accept the share and create VPC attachments in their own accounts.

If you want, I can add a small peering module and a route auto-programmer that consumes:

the VPC CIDRs from both ohio_vpcs and virginia_vpcs, and

the TGW RT IDs from tgw_ohio and tgw_virginia,

…so you don’t have to touch routes when your boss says “add vpc4” 😄

Ahhh got it — you’re running multiple TGWs in different regions with provider aliases (aws.ohio, aws.virginia, etc.).
The key challenge is: your RAM share module needs to know all the TGWs created (one per region) and then create aws_ram_resource_association for each one.

Here’s how we can wire it cleanly:

RAM Share Module (make it generic)

Instead of expecting a single TGW, let’s allow it to take a list of TGW ARNs (from any number of modules).