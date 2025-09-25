# Permission Boundary
resource "aws_iam_policy" "permission_boundary" {
  name        = "${var.company_name}-${var.env}-permission-boundary"
  description = "Permission boundary to restrict access for VPC Flow Logs (CloudWatch + S3)"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowS3LogsAccess",
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${var.log_bucket_name}",
          "arn:aws:s3:::${var.log_bucket_name}/*"
        ]
      },
      {
        Sid    = "AllowCloudWatchLogsAccess",
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/vpc-flow-logs*"
      }
    ]
  })
}


# -------------------------------------------------------
#  Role for VPC Flow Logs
# -------------------------------------------------------

# IAM Role for VPC Flow Logs if cloud-watch-logs is used as destination
resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.company_name}-${var.env}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  permissions_boundary = aws_iam_policy.permission_boundary.arn

  tags = {
    Name = "${var.env}-vpc-flow-logs-role"
  }
}


# IAM Policy for VPC Flow Logs
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


resource "aws_iam_role_policy" "vpc_flow_logs_policy" {
  name = "vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject"
        ],
        Resource = "arn:aws:s3:::${var.log_bucket_name}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ],
        Resource = "arn:aws:s3:::${var.log_bucket_name}"
      }
    ]
  })
}


# --- Admin Role ---
# Admin Policy
data "aws_iam_policy_document" "admin_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = var.admin_role_principals
    }
    actions = ["sts:AssumeRole"]
  }
}

# Admin Role
resource "aws_iam_role" "admin_role" {
  name                 = "${var.company_name}-${var.env}-admin-role"
  assume_role_policy   = data.aws_iam_policy_document.admin_assume.json
  permissions_boundary = var.admin_permissions_boundary_arn
}

# Admin Policy
resource "aws_iam_policy" "admin_policy" {
  name        = "admin-full-access"
  description = "Full admin access for admin role"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "*",
        Resource = "*"
      }
    ]
  })
}

# Admin Role Policy Attachment
resource "aws_iam_role_policy_attachment" "attach_admin_policy" {
  role       = aws_iam_role.admin_role.name
  policy_arn = aws_iam_policy.admin_policy.arn
}


# RBAC Instance Profile
resource "aws_iam_instance_profile" "rbac_instance_profile" {
  name = "GNPC-dev-rbac-instance-profile"
  role = aws_iam_role.admin_role.name
}


# --- Config Role ---
data "aws_iam_policy_document" "config_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = var.config_role_principals
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "config_role" {
  name                 = "${var.company_name}-${var.env}-config-role"
  assume_role_policy   = data.aws_iam_policy_document.config_assume.json
  permissions_boundary = var.config_permissions_boundary_arn
}

resource "aws_iam_policy" "config_policy" {
  name        = "aws-config-policy"
  description = "Policy for AWS Config role"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["config:*", "s3:GetBucketAcl", "s3:PutObject"],
        Resource = [
          var.log_bucket_arn,
          "${var.log_bucket_arn}/*"
        ]
      }
    ]
  })
}

# --- S3 Full Access Role ---
data "aws_iam_policy_document" "s3_full_access_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = var.s3_full_access_role_principals
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "s3_full_access_role" {
  name                 = "${var.company_name}-${var.env}-s3-full-access-role"
  assume_role_policy   = data.aws_iam_policy_document.s3_full_access_assume.json
  permissions_boundary = var.s3_full_access_permissions_boundary_arn
}

resource "aws_iam_policy" "s3_full_access_policy" {
  name        = "s3-full-access"
  description = "Policy for full read/write S3 access"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:*"],
        Resource = [
          var.operations_bucket_arn,
          "${var.operations_bucket_arn}/*"
        ]
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "attach_s3_full_access_policy" {
  role       = aws_iam_role.s3_full_access_role.name
  policy_arn = aws_iam_policy.s3_full_access_policy.arn
}


# --- S3 RW Access Role ---
data "aws_iam_policy_document" "s3_rw_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = var.s3_rw_role_principals
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "s3_rw_role" {
  name                 = "${var.company_name}-${var.env}-s3-rw-role"
  assume_role_policy   = data.aws_iam_policy_document.s3_rw_assume.json
  permissions_boundary = var.s3_rw_permissions_boundary_arn
}

resource "aws_iam_policy" "s3_rw_access" {
  name        = "S3AccessToBucket"
  description = "Allow read/write access to the specified S3 bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.log_bucket_arn,
          "${var.log_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_rw_policy" {
  role       = aws_iam_role.s3_rw_role.name
  policy_arn = aws_iam_policy.s3_rw_access.arn
}



