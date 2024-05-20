terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.45"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~>4.0"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  eks_cluster_name = "${var.resource_prefix}eks"
  eks_tags = merge(var.tags, {
    "platform.nebuly.com/component" : "eks"
  })

  rds_instance_name_analytics = "${var.resource_prefix}platformanalytics"
  rds_instance_name_auth      = "${var.resource_prefix}platformauth"
}

resource "random_string" "secrets_suffix" {
  lower   = true
  length  = 6
  special = false
}


### ----------- Postgres (RDS) ----------- ###
module "rds_postgres_analytics" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~>6.5.5"

  identifier = local.rds_instance_name_analytics

  engine               = "postgres"
  engine_version       = var.rds_postgres_version
  major_engine_version = var.rds_postgres_version
  family               = var.rds_postgres_family
  instance_class       = var.rds_analytics_instance_type

  allocated_storage     = var.rds_analytics_storage.allocated_gb
  max_allocated_storage = var.rds_analytics_storage.max_allocated_gb
  storage_type          = var.rds_analytics_storage.type
  iops                  = var.rds_analytics_storage.iops

  db_name  = "analytics"
  username = var.rds_db_username
  port     = 5432

  password                                = random_password.rds_analytics.result
  manage_master_user_password             = false
  manage_master_user_password_rotation    = false
  master_user_password_rotate_immediately = false

  multi_az          = var.rds_multi_availability_zone_enabled
  availability_zone = var.rds_availability_zone

  vpc_security_group_ids = [
    var.security_group.id
  ]

  maintenance_window              = var.rds_maintenance_window
  backup_window                   = var.rds_backup_window
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true

  backup_retention_period = var.rds_backup_retention_period
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = var.resource_prefix
  monitoring_role_use_name_prefix       = true

  parameters = [
    {
      name : "rds.force_ssl"
      value : "0"
    },
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]

  tags = var.tags
}
resource "random_password" "rds_analytics" {
  length           = 16
  special          = true
  override_special = "!#%&*()-_=+[]{}<>?"
}
resource "aws_secretsmanager_secret" "rds_analytics_credentials" {
  name = format("%s-rds-analytics-credentials-%s", var.resource_prefix, random_string.secrets_suffix.result)
}
resource "aws_secretsmanager_secret_version" "rds_analytics_password" {
  secret_id = aws_secretsmanager_secret.rds_analytics_credentials.id
  secret_string = jsonencode(
    {
      "username" : module.rds_postgres_analytics.db_instance_username,
      "password" : random_password.rds_analytics.result
    }
  )
}

module "rds_postgres_auth" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~>6.5.5"

  identifier = local.rds_instance_name_auth

  engine               = "postgres"
  engine_version       = var.rds_postgres_version
  major_engine_version = var.rds_postgres_version
  family               = var.rds_postgres_family
  instance_class       = var.rds_auth_instance_type

  allocated_storage     = var.rds_auth_storage.allocated_gb
  max_allocated_storage = var.rds_auth_storage.max_allocated_gb
  storage_type          = var.rds_auth_storage.type
  iops                  = var.rds_auth_storage.iops

  db_name  = "auth"
  username = var.rds_db_username
  port     = 5432

  password                                = random_password.rds_auth.result
  manage_master_user_password             = false
  manage_master_user_password_rotation    = false
  master_user_password_rotate_immediately = false

  multi_az = var.rds_multi_availability_zone_enabled

  vpc_security_group_ids = [
    var.security_group.id
  ]

  maintenance_window              = var.rds_maintenance_window
  backup_window                   = var.rds_backup_window
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true

  backup_retention_period = var.rds_backup_retention_period
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = var.resource_prefix
  monitoring_role_use_name_prefix       = true

  parameters = [
    {
      name : "rds.force_ssl"
      value : "0"
    },
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]

  tags = var.tags
}
resource "random_password" "rds_auth" {
  length           = 16
  special          = true
  override_special = "!#%&*()-_=+[]{}<>?"
}
resource "aws_secretsmanager_secret" "rds_auth_credentials" {
  name = format("%s-rds-auth-credentials-%s", var.resource_prefix, random_string.secrets_suffix.result)
}
resource "aws_secretsmanager_secret_version" "rds_auth_password" {
  secret_id = aws_secretsmanager_secret.rds_auth_credentials.id
  secret_string = jsonencode(
    {
      "username" : module.rds_postgres_auth.db_instance_username,
      "password" : random_password.rds_auth.result
    }
  )
}


### ----------- EKS ----------- ###
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~>20.8.5"

  cluster_name    = local.eks_cluster_name
  cluster_version = var.eks_kubernetes_version

  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids
  control_plane_subnet_ids = var.subnet_ids

  cluster_endpoint_public_access = var.eks_cluster_endpoint_public_access

  enable_cluster_creator_admin_permissions = var.eks_enable_cluster_creator_admin_permissions

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
    aws-efs-csi-driver = {
      most_recent = true
    }
  }

  eks_managed_node_group_defaults = var.eks_managed_node_group_defaults

  eks_managed_node_groups = {
    for k, obj in var.eks_managed_node_groups : k => {
      name   = k
      labels = obj.labels

      instance_types = obj.instance_types
      taints         = obj.taints

      min_size                   = obj.min_size
      max_size                   = obj.max_size
      desired_size               = obj.desired_size
      subnet_ids                 = obj.subnet_ids == null ? var.subnet_ids : obj.subnet_ids
      ami_type                   = obj.ami_type
      disk_size                  = obj.disk_size_gb
      use_custom_launch_template = obj.use_custom_launch_template


      iam_role_additional_policies = {
        # Needed by the aws-ebs-csi-driver
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        # Needed by the aws-efs-csi-driver
        AmazonEFSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
      }

      tags = obj.tags
    }
  }

  tags = local.eks_tags
}
module "eks_iam_role" {
  # Role for reading from AWS Secrets Manager through ASCP
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~>5.39.0"

  role_name = local.eks_cluster_name

  attach_external_secrets_policy                     = true
  external_secrets_secrets_manager_create_permission = true
  attach_ebs_csi_policy                              = true
  attach_efs_csi_policy                              = true

  # TODO - it's likely that we don't need these if we use 
  # EKS managed node groups
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [
    module.eks.cluster_name
  ]

  oidc_providers = {
    one = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        for obj in var.eks_service_accounts :
        format("%s:%s", obj.namespace, obj.name)
      ]
    }
  }

  tags = local.eks_tags
}


### ----------- Auth ----------- ###
resource "tls_private_key" "auth_jwt" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_secretsmanager_secret" "auth_jwt_key" {
  # The password of the initial admin user
  name = format("%s-auth-jwt-key-%s", var.resource_prefix, random_string.secrets_suffix.result)
}
resource "aws_secretsmanager_secret_version" "auth_jwt_key" {
  secret_id     = aws_secretsmanager_secret.auth_jwt_key.id
  secret_string = tls_private_key.auth_jwt.private_key_pem
}

resource "random_password" "admin_user_password" {
  length  = 24
  special = true
}
resource "aws_secretsmanager_secret" "admin_user_password" {
  # The password of the initial admin user
  name = format("%s-admin-user-password-%s", var.resource_prefix, random_string.secrets_suffix.result)
}
resource "aws_secretsmanager_secret_version" "admin_user_password" {
  secret_id     = aws_secretsmanager_secret.admin_user_password.id
  secret_string = random_password.admin_user_password.result
}



### ----------- External secrets ----------- ###
resource "aws_secretsmanager_secret" "openai_api_key" {
  name = format("%s-openai-api-key-%s", var.resource_prefix, random_string.secrets_suffix.result)
}
resource "aws_secretsmanager_secret_version" "openai_api_key" {
  secret_id     = aws_secretsmanager_secret.openai_api_key.id
  secret_string = var.openai_api_key
}


### ----------- S3 Storage ----------- ###
resource "aws_s3_bucket" "ai_models" {
  bucket_prefix = format("%s-%s", var.resource_prefix, "ai-models")
  tags          = var.tags
}
resource "aws_iam_role_policy_attachment" "ai_models__eks_reader" {
  role       = module.eks_iam_role.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess" # Attach the read-only S3 access policy
}

