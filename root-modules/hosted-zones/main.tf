# Hosted Zone (referenced by all envs)
module "hosted_zone" {
  source    = "../../modules/hosted-zones"
  domain_name = "company-domain-name.com"

}

