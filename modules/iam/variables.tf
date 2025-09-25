
variable "s3_rw_role_principals" {
  description = "List of service principals for S3 RW role"
  type        = list(string)
  default     = ["ec2.amazonaws.com"]
}

variable "s3_rw_permissions_boundary_arn" {
  description = "ARN of the permissions boundary for S3 RW role"
  type        = string
  default     = null
}

variable "config_role_principals" {
  description = "List of service principals for AWS Config role"
  type        = list(string)
  default     = ["config.amazonaws.com"]
}

variable "config_permissions_boundary_arn" {
  description = "ARN of the permissions boundary for AWS Config role"
  type        = string
  default     = null
}

variable "admin_role_principals" {
  description = "List of service principals for admin role"
  type        = list(string)
  default     = ["ec2.amazonaws.com"]
}

variable "admin_permissions_boundary_arn" {
  description = "ARN of the permissions boundary for admin role"
  type        = string
  default     = null
}

variable "s3_full_access_role_principals" {
  description = "List of service principals for S3 Full Access role"
  type        = list(string)
  default     = ["ec2.amazonaws.com"]
}

variable "s3_full_access_permissions_boundary_arn" {
  description = "ARN of the permissions boundary for S3 Full Access role"
  type        = string
  default     = null
}

variable "env" {
  description = "Environment"
  type = string
}

variable "company_name" {
  description = "Company that owns the Infrastructure"
  type = string
}

variable "operations_bucket_arn" {
  description = "ARN of Operations Bucket"
  type = string
}

variable "log_bucket_arn" {
  description = "ARN of the S3 bucket for S3 RW access"
  type        = string
}

variable "log_bucket_name" {
  description = "Name of the S3 bucket for S3 RW access"
  type        = string
  
}




