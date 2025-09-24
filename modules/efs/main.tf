# Create EFS
resource "aws_efs_file_system" "app_efs" {
  creation_token = "startup-app-efs"
  encrypted      = true
  tags = {
    Name = "startup-app-efs"
  }
}

# Security group for EFS
resource "aws_security_group" "efs_sg" {
  name        = "efs-sg"
  description = "Allow NFS access"
   vpc_id      = var.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    security_groups = var.allowed_sg_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create mount targets in each private subnet
resource "aws_efs_mount_target" "app_efs_targets" {
  for_each = { for idx, subnet_id in var.private_subnets : idx => subnet_id }

  file_system_id  = aws_efs_file_system.app_efs.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs_sg.id]
}
