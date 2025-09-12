
# resource "aws_security_group" "web_sg" {
#   name        = "${var.env}-web-sg"
#   description = "Security group for ${var.env}-web"
#   vpc_id      = var.vpc_id

#   dynamic "ingress" {
#     for_each = var.web_ingress_rules
#     content {
#       description      = lookup(ingress.value, "description", null)
#       from_port        = ingress.value.from_port
#       to_port          = ingress.value.to_port
#       protocol         = ingress.value.protocol
#       cidr_blocks      = lookup(ingress.value, "cidr_blocks", [])
#       ipv6_cidr_blocks = lookup(ingress.value, "ipv6_cidr_blocks", [])
#       prefix_list_ids  = lookup(ingress.value, "prefix_list_ids", [])
#       security_groups  = lookup(ingress.value, "source_security_group_ids", [])
#       self             = lookup(ingress.value, "self", false)
#     }
#   }

#   dynamic "egress" {
#     for_each = var.web_egress_rules
#     content {
#       description      = lookup(egress.value, "description", null)
#       from_port        = egress.value.from_port
#       to_port          = egress.value.to_port
#       protocol         = egress.value.protocol
#       cidr_blocks      = lookup(egress.value, "cidr_blocks", [])
#       ipv6_cidr_blocks = lookup(egress.value, "ipv6_cidr_blocks", [])
#       prefix_list_ids  = lookup(egress.value, "prefix_list_ids", [])
#       security_groups  = lookup(egress.value, "security_groups", [])
#       self             = lookup(egress.value, "self", false)
#     }
#   }

#   tags = merge(
#     var.web_sg_tags,
#     { Name = "${var.env}-web-sg" }
#   )
# }



