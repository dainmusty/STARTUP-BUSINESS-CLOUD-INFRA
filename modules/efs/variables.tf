variable "private_subnets" {
  description = "List of private subnet IDs where EFS mount targets will be created"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where EFS SG should be created"
  type        = string
}

variable "allowed_sg_ids" {
  description = "List of security groups allowed to access EFS"
  type        = list(string)
  default     = []
}
