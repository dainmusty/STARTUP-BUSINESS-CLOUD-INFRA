# Look up the ALB by name
data "aws_lb" "web_alb" {
  name = var.alb_name
}

output "alb_dns_name" { value = data.aws_lb.web_alb.dns_name }
output "alb_zone_id"  { value = data.aws_lb.web_alb.zone_id  }
