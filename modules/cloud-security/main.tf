 # GuardDuty
 resource "aws_guardduty_detector" "guard_duty" {
  enable = true
}

 
# Shield Advanced 
# NOTE: Shield Advanced requires subscription (paid).
# You must enable it once manually in the console or via AWS CLI.

resource "aws_shield_protection" "shield_protect" {
  count        = var.enable_shield ? 1 : 0
  name         = "${var.env}-alb-protection"
  resource_arn = var.alb_arn
}

 
# WAFv2 Web ACL
resource "aws_wafv2_ip_set" "bad_ips" {
  name               = "${var.env}-bad-ips"
  description        = "Blocked IPs"
  scope              = var.waf_scope # "REGIONAL" or "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.blocked_ips
}

resource "aws_wafv2_web_acl" "waf_acl" {
  name  = "${var.env}-waf"
  scope = var.waf_scope

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.env}-waf-metric"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "block-bad-ips"
    priority = 1

    action {
      block {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.bad_ips.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "block-bad-ips"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_wafv2_web_acl_association" "waf_assoc" {
  count        = var.associate_alb ? 1 : 0
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.waf_acl.arn
}

