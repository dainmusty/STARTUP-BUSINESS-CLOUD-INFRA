output "domain_name"                 { value = var.domain_name }
output "hosted_zone_id"                   { value = aws_route53_zone.dev_hosted_zone.zone_id }

