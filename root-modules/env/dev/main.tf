# # VPC Module
module "vpc" {
  source = "../../../modules/vpc"

  vpc_cidr              = "10.1.0.0/16"
  ResourcePrefix        = "GNPC-Dev"
  enable_dns_hostnames  = true
  enable_dns_support    = true
  instance_tenancy      = "default"
  public_subnet_cidr    = ["10.1.1.0/24", "10.1.2.0/24"] 
  private_subnet_cidr   = ["10.1.3.0/24", "10.1.4.0/24"] 
  availability_zones    = ["us-east-1a", "us-east-1b"]
  public_ip_on_launch   = true
  PublicRT_cidr         = "0.0.0.0/0"
  cluster_name          = "effulgencetech-dev"
  PrivateRT_cidr        = "0.0.0.0/0"
  eip_associate_with_private_ip = true
}


# Security Groups Module
# ALB SG
module "alb_sg" {
  source          = "../../../modules/security/alb"
  vpc_id          = module.vpc.vpc_id
  env = "Dev"

  alb_sg_ingress_rules = [
    {
      description = "Allow HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  alb_sg_egress_rules = [
    {
      description = "Allow all egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  alb_sg_tags = {
  "Name"        = "dev-alb-sg"
  "Project"     = "Startup"
  "Environment" = "dev"
  "ManagedBy"   = "Terraform"
}

}

# WEB SG
module "web_sg" {
  source          = "../../../modules/security/web"
  vpc_id          = module.vpc.vpc_id
  env = "Dev"

  web_ingress_rules = [
    {
      description              = "Allow traffic from ALB"
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      source_security_group_ids = [module.alb_sg.alb_sg_id]
    }
  ]

  web_egress_rules = [
    {
      description = "Allow all egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  web_sg_tags = {
    Name        = "web-sg"
    Environment = "Dev"
  }

}



# DB SG
module "db_sg" {
  source          = "../../../modules/security/db"
  vpc_id          = module.vpc.vpc_id
  env = "Dev"

  db_sg_ingress_rules = [
    {
      description              = "Allow MySQL from web tier"
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      source_security_group_ids = [module.web_sg.web_sg_id]
    }
  ]

  db_sg_egress_rules = [
    {
      description = "Allow all egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  db_sg_tags = {
    Name        = "db-sg"
    Environment = "Dev"
  }
  # Cache Security Group
  cache_source_sg = [module.web_sg.web_sg_id]  # only app servers can talk to cache
}


# MONITORING SG
module "monitoring_sg" {
  source          = "../../../modules/security/monitoring"
  vpc_id          = module.vpc.vpc_id
  env = "Dev"

  monitoring_ingress_rules = [
    {
      description = "Allow Prometheus"
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow Grafana"
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  monitoring_egress_rules = [
    {
      description = "Allow all egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  monitoring_sg_tags = {
    Name        = "monitoring-sg"
    Environment = "Dev"
  }

}



module "alb_asg" {
  source = "../../../modules/alb-asg" # adjust path to where you put the module

  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.public_subnets
  web_sg_id           = module.web_sg.web_sg_id
  alb_sg_id           = [module.alb_sg.alb_sg_id] # ALB SG expects a list
  ami_id              = "ami-08b5b3a93ed654d19" # Amazon Linux 2023 AMI ID in us-east-1 as of April 2024
  instance_type       = "t2.micro"
  key_name            = "us-east-1-musty"
  user_data           = file("${path.module}/../../../scripts/public_userdata.sh") # Update the user_data script as needed

  launch_template_name = "startup-web-lt"
  asg_name             = "startup-web-asg"
  asg_min_size         = 1
  asg_max_size         = 2
  asg_desired_capacity = 1

  alb_name          = "startup-web-alb"
  target_group_name = "startup-web-tg"
  app_port          = 3000
  alb_type          = "application"
}




# # EC2 Module
module "ec2" {
  source = "../../../modules/ec2"

  ResourcePrefix             = "GNPC-Dev"
  ami_ids                    = ["ami-08b5b3a93ed654d19", "ami-02a53b0d62d37a757", "ami-02e3d076cbd5c28fa", "ami-0c7af5fe939f2677f", "ami-04b4f1a9cf54c11d0"]
  ami_names                  = ["AL2023", "AL2", "Windows", "RedHat", "ubuntu"]
  instance_types             = ["t2.micro", "t2.micro", "t2.micro", "t2.micro", "t2.micro"]
  key_name                   = module.ssm.key_name_parameter_value
  instance_profile_name      = module.iam.rbac_instance_profile_name
  public_instance_count      = [0, 0, 0, 0, 0]
  private_instance_count     = [0, 0, 0, 0, 0]

  tag_value_public_instances = [
    [
      {
        Name        = "app_servers"
        Environment = "Dev"
      },
      
    ],
    [], [], [], []
  ]

  tag_value_private_instances = [
    [],
    [
      {
        Name = "db1"
        Tier = "Database"
      }
    ],
    [],
    [], []
  ]

  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnets
  private_subnet_ids         = module.vpc.private_subnets
  public_sg_id               = module.web_sg.web_sg_id
  private_sg_id              = module.db_sg.db_sg_id
  volume_size                = 8
  volume_type                = "gp3"
}



# # IAM Module
module "iam" {
  source = "../../../modules/iam"

  # Resource Tags
  env          = "dev"
  
  company_name = "Startup"

  # Role Services Allowed
  admin_role_principals          = ["ec2.amazonaws.com", "cloudwatch.amazonaws.com", "config.amazonaws.com", "apigateway.amazonaws.com", "ssm.amazonaws.com"]  # Only include the services that actually need to assume the role.
  
  s3_rw_role_principals          = ["ec2.amazonaws.com"]
  config_role_principals         = ["config.amazonaws.com"]
  s3_full_access_role_principals = ["ec2.amazonaws.com"]

  # Permission Boundaries
  admin_permissions_boundary_arn         = module.iam.permission_boundary_arn   # If you are not required to apply the permission boundary, then your value will be "null"
  config_permissions_boundary_arn        = module.iam.permission_boundary_arn
  s3_full_access_permissions_boundary_arn = module.iam.permission_boundary_arn
  s3_rw_permissions_boundary_arn         = module.iam.permission_boundary_arn

  # S3 Buckets Referenced
  log_bucket_arn        = module.s3.operations_bucket_arn
  operations_bucket_arn = module.s3.log_bucket_arn


}



# # S3 Module
module "s3" {
  source                          = "../../../modules/s3"
  config_bucket_name = module.s3.config_bucket_name
  config_key_prefix = "config-logs"
  config_role_arn = module.iam.config_role_arn
  log_bucket_name                      = "startup-dev-log-bucket"
  operations_bucket_name          = "startup-dev-operations-bucket"
  replication_bucket_name = "startup-replication-bucket"
  log_bucket_versioning_status = "Enabled"
  operations_bucket_versioning_status    = "Enabled"
  replication_bucket_versioning_status   = "Enabled"
  logging_prefix                  = "logs/"
  ResourcePrefix                  = "Dev"
  tags                            = {
    Environment = "dev"
    Project     = "startup"
  }
}



# # AWS Config Module
# module "config_rules" {
#   source = "../../../modules/compliance"
#   config_role_arn           = module.iam.config_role_arn
#   config_bucket_name     = module.s3.log_bucket_name  # This is the bucket where AWS Config stores configuration history and snapshot files. The config bucket is actually the log bucket.
#   config_s3_key_prefix      = "config-logs"

#   recorder_status_enabled               = true 
#   recording_gp_all_supported            = true 
#   recording_gp_global_resources_included = true 

#   config_rules = [
#     {
#       name              = "restricted-incoming-traffic"
#       source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
#     },
#     {
#       name              = "required-tags"
#       source_identifier = "REQUIRED_TAGS"
#       input_parameters  = jsonencode({ tag1Key = "Owner", tag2Key = "Environment" })
#       compliance_resource_types = ["AWS::EC2::Instance"]
#     },
#     {
#       name              = "dev-s3-public-read-prohibited"
#       source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
#     },
#     {
#       name              = "dev-cloudtrail-enabled"
#       source_identifier = "CLOUD_TRAIL_ENABLED"
#     }
#   ]
# }




module "db" {
  source = "../../../modules/rds"

  # RDS Variables
  identifier              = "dev-db"
  db_engine               = "postgres"
  db_engine_version       = "15.5"
  instance_class          = "db.t3.micro"
  allocated_storage       = 10
  db_name                 = "mydb"
  username                = module.ssm.db_access_parameter_value
  password                = module.ssm.db_secret_parameter_value
  vpc_security_group_ids  = [module.db_sg.db_sg_id]   # from SG module
  subnet_ids              = module.vpc.private_subnets
  db_subnet_group_name    = "rds-subnet-group"
  multi_az                = true
  storage_type            = "gp3"
  backup_retention_period = 7
  skip_final_snapshot     = true
  publicly_accessible     = false
  env                     = "dev"
  db_tags = {
    Name        = "rds-instance"
    Environment = "Dev"
    Owner       = "startup"
  }

  # ElastiCache Variables
  node_type       = "cache.t3.micro"
  num_cache_nodes = 2
  cache_sg_ids    = [module.db_sg.cache_sg_id]  # from SG module
}




module "ssm" {
  source         = "../../../modules/ssm"
  db_access_parameter_name  = "/db/access"
  db_secret_parameter_name  = "/db/secure/access"
  key_path_parameter_name   = "/kp/path"
  key_name_parameter_name   = "/kp/name"

}




# # CloudFront and Route53 Module
module "cdn_route53" {
  source = "../../../modules/cdn-route53"

  # AWS region where your EKS + ALB are deployed
  region = "us-east-1"

  # The root domain you want to register & host in Route 53
  hosted_zone_name = "company-domain-name.com"

  # Two subdomains (will map to two CloudFront distributions)
  app_domain_primary   = "app.company-domain-name.com"
  app_domain_secondary = "api.company-domain-name.com"

  # ALB name as set by your Ingress annotation
  # e.g. alb.ingress.kubernetes.io/load-balancer-name: eks-alb
  alb_name = "eks-alb"

  # Enable or disable CloudFront logging
  enable_cf_logging = true

  # Pre-created S3 bucket for CloudFront logs
  log_bucket_name = module.s3.log_bucket_name


}

module "efs" {
  source          = "../../../modules/efs"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  allowed_sg_ids  = [module.web_sg.web_sg_id]
  
}





