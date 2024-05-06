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
  }
}

locals {
  eks_cluster_name = "${var.resource_prefix}eks"
  eks_tags = merge(var.tags, {
    "platform.nebuly.com/component" : "eks"
  })

  rds_instance_name_analytics = "${var.resource_prefix}platformanalytics"
  rds_instance_name_auth      = "${var.resource_prefix}platformauth"
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

  multi_az = var.rds_multi_availability_zone_enabled

  vpc_security_group_ids = [
    data.aws_security_group.default.id
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
  name = format("%s-rds-analytics-credentials", var.resource_prefix)
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
    data.aws_security_group.default.id
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
  name = format("%s-rds-auth-credentials", var.resource_prefix)
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

  vpc_id                         = var.vpc_id
  subnet_ids                     = var.subnet_ids
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
  }

  eks_managed_node_group_defaults = var.eks_managed_node_group_defaults

  eks_managed_node_groups = {
    for k, obj in var.eks_managed_node_groups : k => {
      name = k

      instance_types = obj.instance_types

      min_size     = obj.min_size
      max_size     = obj.max_size
      desired_size = obj.desired_size
    }
  }

  tags = local.eks_tags
}
module "eks_iam_role" {
  # Role for reading from AWS Secrets Manager trhough ASCP
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~>5.39.0"

  role_name = local.eks_cluster_name

  attach_external_secrets_policy                     = true
  external_secrets_secrets_manager_create_permission = true

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


### ----------- External secrets ----------- ###
resource "aws_secretsmanager_secret" "openai_api_key" {
  name = format("%s-openai-api-key", var.resource_prefix)
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

