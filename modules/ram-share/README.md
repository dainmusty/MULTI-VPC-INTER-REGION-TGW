module "web_sg_ohio" {
  source = "../modules/sgs"
  vpc_id = module.vpc_ohio.vpc_id
  env    = "GNPC-Dev-Ohio"
  web_ingress_rules = [
  {
    description = "Allow traffic from TGW"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  },
  {
    description = "Allow ICMP traffic"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
]
  
  

  web_egress_rules = [
    {
      description = "Allow all egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  web_sg_tags = {
    Name        = "web-sg"
    Environment = "Dev"
  }
}

module "web_sg_virginia" {
  source = "../modules/sgs"
  vpc_id = module.vpc_virginia.vpc_id
  env    = "GNPC-Dev-Virginia"
  web_ingress_rules = [
    {
                  description = "Allow traffic from TGW"
                  from_port   = 22
                  to_port     = 22
                  protocol    = "tcp"
                  cidr_blocks = ["0.0.0.0/0"]
    },
    {
                  description = "Allow ICMP traffic"
                  from_port   = -1
                  to_port     = -1
                  protocol    = "icmp"
                  cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  

  web_egress_rules = [
    {
      description = "Allow all egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  web_sg_tags = {
    Name        = "web-sg"
    Environment = "Dev"
  }
}


2. Why toset() in for_each?

for_each needs either:

a map ({ key = value })

or a set of strings (toset([...]))

It does not allow a plain list, because lists are indexed (0, 1, 2...) and those aren’t stable keys across runs.

So if you pass a list(string) to for_each, Terraform will complain:

The "for_each" map includes keys derived from resource addresses, which is not allowed.


That’s why we wrap lists with toset() — it converts the list into a set of strings, which Terraform can safely use as keys.

3. Your case

Since you declared:

variable "tgw_arns" {
  type = list(string)
}


And then wrote:

for_each = toset(var.tgw_arns)


Terraform converts that list → set.
That way each TGW ARN becomes a unique key in the loop.

✅ TL;DR:

Square brackets [] = list.

toset([...]) = set.

for_each doesn’t accept lists directly, so we wrap with toset().

Do you also want me to extend this so the target account(s) can automatically accept the share (using aws_ram_resource_share_accepter + provider aliases with assume_role), or do you want to keep that separate?



 The "for_each" set includes values derived from resource attributes that cannot be   
│ determined until apply, and so Terraform cannot determine the full set of keys that  
│ will identify the instances of this resource.
│
│ When working with unknown values in for_each, it's better to use a map value where   
│ the keys are defined statically in your configuration and where only the values      
│ contain apply-time results.
│
│ Alternatively, you could use the -target planning option to first apply only the     
│ resources that the for_each value depends on, and then apply a second time to fully  
│ converge.
╵
ChatGPT said:

Ah, this is the same "for_each with unknown values at plan time" problem we saw earlier with TGW attachments 👍.

Terraform can’t build a toset(var.tgw_arns) because the ARNs (module.tgw_*.tgw_arn) don’t exist until apply time.

✅ Fix: use a map instead of a list

Instead of passing a list of TGW ARNs, pass a map with static keys (the values can still be dynamic). That way, Terraform always knows the keys at plan time.

Child module (modules/ram-share/main.tf)
resource "aws_ram_resource_association" "resource_assoc" {
  for_each = var.tgw_arns

  resource_arn       = each.value
  resource_share_arn = aws_ram_resource_share.tgw_share.arn
}

Variables (modules/ram-share/variables.tf)
variable "tgw_arns" {
  description = "Map of TGW ARNs to share"
  type        = map(string)
}

Root module call

Instead of:

tgw_arns = [module.tgw_virginia.tgw_arn, module.tgw_ohio.tgw_arn]


Do this:

tgw_arns = {
  virginia = module.tgw_virginia.tgw_arn
  ohio     = module.tgw_ohio.tgw_arn
}


✅ This way:

Keys (virginia, ohio) are known at plan time.

Values (the TGW ARNs) can be computed at apply time.

No more "Invalid for_each argument" error.