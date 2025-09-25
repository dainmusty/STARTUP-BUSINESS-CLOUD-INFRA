output "guardduty_id" {
  value = aws_guardduty_detector.guard_duty.id
}

output "waf_acl_arn" {
  value = aws_wafv2_web_acl.waf_acl.arn
}

output "shield_protection_id" {
  value = var.enable_shield ? aws_shield_protection.shield_protect[0].id : null
}

