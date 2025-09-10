⚠️ Note: Peering is always initiated in one TGW’s region (the requester), but you need the accepter to be in the other region/account. That’s why the aws_ec2_transit_gateway_peering_attachment_accepter is critical. You might need to run the accepter with a different provider alias if it’s in another AWS account/region.

when do you mean when say "You might need to run the accepter with a different provider alias if it’s in another AWS account/region". can you explain? does it mean i have to go and accept in the console? the accepter is ohio. i have updated the root call, see below

module "tgw_peering_ohio_virginia" {
  source = "../modules/tgw-peering"

  providers = {
    aws = aws.ohio
  }

  requester_tgw_id = module.tgw_virginia.tgw_id
  accepter_tgw_id  = module.tgw_ohio.tgw_id
  accepter_region  = "us-east-2"

  tags = {
    Project = "tankofm-inter-region-vpc-project"
    Env     = "dev"
  }
}
ChatGPT said:

Great question — let’s clear this up 👇

When you create a TGW peering:

Requester → sends the peering request (aws_ec2_transit_gateway_peering_attachment).

Accepter → must accept it (aws_ec2_transit_gateway_peering_attachment_accepter).

Now:

If both TGWs are in the same AWS account, Terraform can handle both requester and accepter in one apply, as long as you have the right provider aliases for each region.

If the TGWs are in different AWS accounts, then the accepter resource must use the provider for that other account — otherwise Terraform won’t have the credentials to accept it.

In your case:

Requester = Virginia TGW (us-east-1)

Accepter = Ohio TGW (us-east-2)

So you need two providers:

aws.virginia → to create the requester.

aws.ohio → to accept the request.

✅ Fixing your module call

Right now you’re only passing providers = { aws = aws.ohio }. That means both resources (requester + accepter) will run in Ohio. But the requester TGW is in Virginia, so Terraform will fail or create it in the wrong region.

Instead, you need to wire two providers to your tgw-peering module:

module "tgw_peering_ohio_virginia" {
  source = "../modules/tgw-peering"

  providers = {
    aws.requester = aws.virginia
    aws.accepter  = aws.ohio
  }

  requester_tgw_id = module.tgw_virginia.tgw_id
  accepter_tgw_id  = module.tgw_ohio.tgw_id
  accepter_region  = "us-east-2"

  tags = {
    Project = "tankofm-inter-region-vpc-project"
    Env     = "dev"
  }
}

✅ Inside the module (modules/tgw-peering/main.tf)

Update resource blocks to use the right provider:

resource "aws_ec2_transit_gateway_peering_attachment" "this" {
  provider = aws.requester

  transit_gateway_id      = var.requester_tgw_id
  peer_transit_gateway_id = var.accepter_tgw_id
  peer_region             = var.accepter_region

  tags = merge(var.tags, {
    Name = "tgw-peering-${var.requester_tgw_id}-${var.accepter_tgw_id}"
  })
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "this" {
  provider = aws.accepter

  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.this.id

  tags = merge(var.tags, {
    Name = "tgw-peering-accept-${var.requester_tgw_id}-${var.accepter_tgw_id}"
  })
}


👉 With this:

Terraform will create the peering request in Virginia.

Terraform will also accept the request in Ohio.

You don’t need to go into the console manually.

Do you want me to also show you how to generalize this module further, so you can peer any TGWs across any regions/accounts just by passing provider aliases? That way, you’ll never have to modify the module again.

Reusability Win

Now you can peer any TGWs just by:

Passing in requester_tgw_id, requester_region, accepter_tgw_id, accepter_region.

Attaching the right providers (aws.requester, aws.accepter).

If in the future you need to peer two TGWs in different accounts, just point the providers to different AWS profiles/accounts. The module won’t change.

Got it ✅
Peering TGWs across different AWS accounts works the same way as across regions — the only difference is:

Requester TGW is in one account (e.g., Network account).

Accepter TGW is in another account (e.g., Prod account).

Terraform needs two providers pointing to two different AWS accounts.

The aws_ec2_transit_gateway_peering_attachment is created in the requester’s account.

The aws_ec2_transit_gateway_peering_attachment_accepter is created in the accepter’s account.

1️⃣ Providers setup (root main.tf)

Here’s how you define providers for two accounts:

provider "aws" {
  alias  = "network"
  region = "us-east-1"
  profile = "network-account" # or use assume_role block
}

provider "aws" {
  alias  = "prod"
  region = "us-east-2"
  profile = "prod-account"
}


If you’re using IAM roles instead of profiles, replace profile with:

assume_role {
  role_arn = "arn:aws:iam::<account_id>:role/TerraformExecutionRole"
}

2️⃣ Root module call

Now wire the providers into your peering module:

module "tgw_peering_network_prod" {
  source = "../modules/tgw-peering"

  providers = {
    aws.requester = aws.network
    aws.accepter  = aws.prod
  }

  requester_tgw_id = module.tgw_network.tgw_id
  requester_region = "us-east-1"

  accepter_tgw_id  = module.tgw_prod.tgw_id
  accepter_region  = "us-east-2"

  tags = {
    Project = "tankofm-inter-region-vpc-project"
    Env     = "prod"
  }
}

3️⃣ Inside the module (no change needed)

The same tgw-peering module you built before will work — because we’re simply passing different provider aliases that point to different accounts.

🔑 Key Points

Requester creates the attachment (in Account A).

Accepter accepts the attachment (in Account B).

Terraform handles both sides if you give it access to both accounts (via provider aliases).

You do not need to manually accept anything in the console.

⚡ So once you have network + prod providers set up, you can reuse the same module to peer any TGWs across accounts.


plan worked but the warning below
88 to add, 0 to change, 0 to destroy.
╷
│ Warning: Reference to undefined provider
│
│   on main.tf line 172, in module "tgw_peering_ohio_virginia":
│  172:     aws.requester = aws.virginia
│
│ There is no explicit declaration for local provider name "aws.requester" in
│ module.tgw_peering_ohio_virginia, so Terraform is assuming you mean to pass a        
│ configuration for "hashicorp/aws".
│
│ If you also control the child module, add a required_providers entry named
│ "aws.requester" with the source address "hashicorp/aws".
│
│ (and one more similar warning elsewhere)
╵

─────────────────────
ChatGPT said:

Ah nice catch 👍 That warning is Terraform telling you:

“You’re passing aws.requester and aws.accepter into the module, but the child module hasn’t declared those provider aliases as expected.”

✅ Fix: Add required_providers block inside your tgw-peering module

In modules/tgw-peering/versions.tf (or main.tf if you don’t have versions.tf), declare the aliased providers explicitly:

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
      configuration_aliases = [aws.requester, aws.accepter]
    }
  }
}

Why this is needed?

At the root, you said:

providers = {
  aws.requester = aws.virginia
  aws.accepter  = aws.ohio
}


Terraform needs to know that the child module expects two different AWS configs (aws.requester, aws.accepter).

Without the configuration_aliases declaration, Terraform assumes you meant the default aws provider, hence the warning

# try this next
Do you want me to also show you how to make your tgw-peering module multi-account + multi-region reusable in one go (so you can just pass in a list of peerings and it builds all of them with no duplicate module calls)?


Option 1: One module call per provider pair

✅ Pros

Simple to reason about (each call is clearly for one requester/accepter pair).

Easier to debug when something goes wrong — you know exactly which module block it came from.

Less Terraform magic (no dynamic provider switching inside loops).

❌ Cons

Repetition: if you have 5+ peerings, you’ll end up with 5+ module calls.

Harder to scale in organizations with many TGWs.

Option 2: Dynamic per-peering providers (aliases inside map)

✅ Pros

Highly reusable — just add a new entry in peerings and you’re done.

Keeps your root config very DRY (no copy/paste module blocks).

Fits well if you expect a lot of peerings or multi-account/multi-region scaling.

❌ Cons

Slightly more complex — you need to carefully maintain provider aliases in both root and module.

Debugging can be trickier since provider is chosen dynamically per entry.

Requires Terraform 0.13+ for dynamic provider selection (provider = aws.${each.value.alias}).

🚀 Best Practice Recommendation

If you only have a handful of peerings (say ≤3–5), go with Option 1 (one module per pair) → simpler, more explicit, less “Terraform gymnastics”.

If your org is scaling into many regions/accounts and peerings will keep growing, invest the time to implement Option 2 (dynamic per-peering providers) → it’ll pay off in maintainability and DRYness.

Multi-Region

You specify different provider aliases (e.g., aws.virginia, aws.ohio).

Terraform automatically talks to those regions via the aliased providers.

In your example:

aws.requester = aws.virginia → requester TGW lives in us-east-1

aws.accepter = aws.ohio → accepter TGW lives in us-east-2

The peer_region argument tells AWS that the attachment is cross-region. ✅

So yes, this setup is multi-region ready.

🔹 Multi-Account

To make it multi-account, you just extend the provider aliases.
For example:

provider "aws" {
  alias   = "virginia"
  region  = "us-east-1"
  profile = "network-account" # Account A
}

provider "aws" {
  alias   = "ohio"
  region  = "us-east-2"
  profile = "prod-account" # Account B
}


Then the exact same module call works — because Terraform will assume the role (or use the profile) for the correct account per alias.
The only extra requirement is RAM share: TGWs in different accounts must be shared via AWS RAM so that Account B can see the TGW from Account A. You’ve already started on that earlier with your ram-share module. ✅

🔹 Summary

✅ Multi-Region → already handled by using two provider aliases in different regions.

✅ Multi-Account → handled by pointing those provider aliases at different accounts (via profile, assume_role, etc.) + RAM share.

✅ Your module design is already flexible enough to do both.