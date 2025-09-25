variable "env" {
  description = "Prefix name for resources"
  type        = string
}

variable "enable_shield" {
  description = "Enable AWS Shield Advanced protection"
  type        = bool
  default     = false
}

variable "alb_arn" {
  description = "ARN of the Application Load Balancer"
  type        = string
  default     = ""
}

variable "waf_scope" {
  description = "Scope of the WAF (REGIONAL or CLOUDFRONT)"
  type        = string
  default     = "REGIONAL"
}

variable "associate_alb" {
  description = "Whether to associate WAF with ALB"
  type        = bool
  default     = false
}

variable "waf_rules" {
  description = "Custom WAF rules list"
  type = list(object({
    name        = string
    priority    = number
    ip_set_arn  = string
    metric_name = string
  }))
  default = []
}

variable "blocked_ips" {
  description = "List of IPs to block"
  type        = list(string)
  default     = []
  
}
 

 
 
 