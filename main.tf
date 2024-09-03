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

data "aws_partition" "current" {}
data "aws_subnet" "subnets" {
  for_each = var.subnet_ids

  id = each.value
}

resource "random_string" "secrets_suffix" {
  lower   = true
  length  = 6
  special = false
}

locals {
  partition = data.aws_partition.current.partition

  secrets_suffix     = var.secrets_suffix == null ? random_string.secrets_suffix.result : var.secrets_suffix
  use_secrets_suffix = length(local.secrets_suffix) > 0

  eks_cluster_name = "${var.resource_prefix}eks"
  eks_tags = merge(var.tags, {
    "platform.nebuly.com/component" : "eks"
  })
  eks_load_balancer_name = "${var.resource_prefix}-eks-load-balancer"
  eks_cluster_admin_access_entries = {
    for arn in var.eks_cluster_admin_arns :
    arn => {
      principal_arn = arn
      type          = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn = "arn:${local.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

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

  create_db_subnet_group = var.rds_create_db_subnet_group
  multi_az               = var.rds_multi_availability_zone_enabled
  availability_zone      = var.rds_availability_zone

  vpc_security_group_ids = [
    var.security_group.id
  ]
  subnet_ids = var.subnet_ids

  maintenance_window              = var.rds_maintenance_window
  backup_window                   = var.rds_backup_window
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true

  backup_retention_period = var.rds_backup_retention_period
  skip_final_snapshot     = true
  deletion_protection     = var.rds_deletion_protection

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
  name = (
    local.use_secrets_suffix ?
    format("%s-rds-analytics-credentials-%s", var.resource_prefix, local.secrets_suffix) :
    format("%s-rds-analytics-credentials", var.resource_prefix)
  )
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
  create_db_subnet_group          = var.rds_create_db_subnet_group
  subnet_ids                      = var.subnet_ids

  backup_retention_period = var.rds_backup_retention_period
  skip_final_snapshot     = true
  deletion_protection     = var.rds_deletion_protection

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
  name = (
    local.use_secrets_suffix ?
    format("%s-rds-auth-credentials-%s", var.resource_prefix, local.secrets_suffix) :
    format("%s-rds-auth-credentials", var.resource_prefix)
  )
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
locals {
  base_cluster_addons = {
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
}
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
  access_entries                           = local.eks_cluster_admin_access_entries

  cluster_addons = merge(
    local.base_cluster_addons,
    var.eks_cloudwatch_observability_enabled == true ? {
      amazon-cloudwatch-observability = {
        most_recent = true
      }
    } : {}
  )

  eks_managed_node_group_defaults = var.eks_managed_node_group_defaults

  eks_managed_node_groups = {
    for k, obj in var.eks_managed_node_groups : k => {
      name   = k
      labels = obj.labels

      instance_types = obj.instance_types
      taints         = obj.taints

      min_size     = obj.min_size
      max_size     = obj.max_size
      desired_size = obj.desired_size
      subnet_ids   = obj.subnet_ids == null ? var.subnet_ids : obj.subnet_ids
      ami_type     = obj.ami_type
      disk_size    = obj.disk_size_gb

      use_custom_launch_template = obj.use_custom_launch_template
      launch_template_tags       = obj.tags


      iam_role_additional_policies = {
        # Needed by the aws-ebs-csi-driver
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        # Needed by the aws-efs-csi-driver
        AmazonEFSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
        # Needed by CloudWatch agent
        CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
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
  attach_cloudwatch_observability_policy             = true
  attach_ebs_csi_policy                              = true
  attach_efs_csi_policy                              = true
  attach_load_balancer_controller_policy             = true

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
  name = (
    local.use_secrets_suffix ?
    format("%s-auth-jwt-key-%s", var.resource_prefix, local.secrets_suffix) :
    format("%s-auth-jwt-key", var.resource_prefix)
  )
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
  name = (
    local.use_secrets_suffix ?
    format("%s-admin-user-password-%s", var.resource_prefix, local.secrets_suffix) :
    format("%s-admin-user-password", var.resource_prefix)
  )
}
resource "aws_secretsmanager_secret_version" "admin_user_password" {
  secret_id     = aws_secretsmanager_secret.admin_user_password.id
  secret_string = random_password.admin_user_password.result
}



# ----------- Networking ----------- #
resource "aws_security_group" "eks_load_balancer" {
  name        = local.eks_load_balancer_name
  description = "Rules for the EKS load balancer."
  vpc_id      = var.vpc_id

  # Allow all outbound traffix
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = local.eks_load_balancer_name
  }
}
resource "aws_vpc_security_group_ingress_rule" "eks_load_balancer_allow_https" {
  for_each = var.allowed_inbound_cidr_blocks

  security_group_id = aws_security_group.eks_load_balancer.id
  cidr_ipv4         = each.value
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}
resource "aws_vpc_security_group_ingress_rule" "eks_load_balancer_allow_http" {
  for_each = var.allowed_inbound_cidr_blocks

  security_group_id = aws_security_group.eks_load_balancer.id
  cidr_ipv4         = each.value
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# --- optionally configure security group rules ---- #
resource "aws_security_group_rule" "allow_all_inbound_within_vpc" {
  count = var.create_security_group_rules ? 1 : 0

  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1" # -1 means all protocols
  cidr_blocks = [for k, v in data.aws_subnet.subnets : v.cidr_block]

  security_group_id = var.security_group.id
}
resource "aws_security_group_rule" "allow_all_outbound_within_vpc" {
  count = var.create_security_group_rules ? 1 : 0

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1" # -1 means all protocols
  cidr_blocks = [for k, v in data.aws_subnet.subnets : v.cidr_block]

  security_group_id = var.security_group.id
}



# ----------- External secrets ----------- #
resource "aws_secretsmanager_secret" "openai_api_key" {
  name = (
    local.use_secrets_suffix ?
    format("%s-openai-api-key-%s", var.resource_prefix, local.secrets_suffix) :
    format("%s-openai-api-key", var.resource_prefix)
  )
}
resource "aws_secretsmanager_secret_version" "openai_api_key" {
  secret_id     = aws_secretsmanager_secret.openai_api_key.id
  secret_string = var.openai_api_key
}
resource "aws_secretsmanager_secret" "nebuly_credentials" {
  name = (
    local.use_secrets_suffix ?
    format("%s-nebuly-credentials-%s", var.resource_prefix, local.secrets_suffix) :
    format("%s-nebuly-credentials", var.resource_prefix)
  )
}
resource "aws_secretsmanager_secret_version" "nebuly_credentials" {
  secret_id = aws_secretsmanager_secret.nebuly_credentials.id
  secret_string = jsonencode(
    {
      "client_id" : var.nebuly_credentials.client_id
      "client_secret" : var.nebuly_credentials.client_secret
    }
  )
}



# ----------- S3 Storage ----------- #
resource "aws_s3_bucket" "ai_models" {
  bucket_prefix = format("%s-%s", var.resource_prefix, "ai-models")
  tags          = var.tags
}
resource "aws_iam_role_policy_attachment" "ai_models__eks_reader" {
  role       = module.eks_iam_role.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess" # Attach the read-only S3 access policy
}



# ------ Post provisioning ------ #
locals {
  secret_provider_class_name        = "nebuly-platform"
  secret_provider_class_secret_name = "nebuly-platform-credentials"

  # k8s secrets keys
  k8s_secret_key_analytics_db_username = "analytics-db-username"
  k8s_secret_key_analytics_db_password = "analytics-db-password"
  k8s_secret_key_auth_db_username      = "auth-db-username"
  k8s_secret_key_auth_db_password      = "auth-db-password"
  k8s_secret_key_jwt_signing_key       = "jwt-signing-key"
  k8s_secret_key_openai_api_key        = "openai-api-key"
  k8s_secret_key_nebuly_client_id      = "nebuly-azure-client-id"
  k8s_secret_key_nebuly_client_secret  = "nebuly-azure-client-secret"

  bootstrap_helm_values = templatefile(
    "${path.module}/templates/helm-values-bootstrap.tpl.yaml",
    {

      eks_cluster_name = local.eks_cluster_name
      eks_iam_role_arn = module.eks_iam_role.iam_role_arn
    }
  )
  helm_values = templatefile(
    "${path.module}/templates/helm-values.tpl.yaml",
    {
      platform_domain        = var.platform_domain
      image_pull_secret_name = var.k8s_image_pull_secret_name

      openai_endpoint               = var.openai_endpoint
      openai_frustration_deployment = var.openai_gpt4_deployment_name

      secret_provider_class_name        = local.secret_provider_class_name
      secret_provider_class_secret_name = local.secret_provider_class_secret_name

      k8s_secret_key_analytics_db_username = local.k8s_secret_key_analytics_db_username
      k8s_secret_key_analytics_db_password = local.k8s_secret_key_analytics_db_password
      k8s_secret_key_auth_db_username      = local.k8s_secret_key_auth_db_username
      k8s_secret_key_auth_db_password      = local.k8s_secret_key_auth_db_password

      k8s_secret_key_jwt_signing_key      = local.k8s_secret_key_jwt_signing_key
      k8s_secret_key_openai_api_key       = local.k8s_secret_key_openai_api_key
      k8s_secret_key_nebuly_client_secret = local.k8s_secret_key_nebuly_client_secret
      k8s_secret_key_nebuly_client_id     = local.k8s_secret_key_nebuly_client_id

      s3_bucket_name = aws_s3_bucket.ai_models.bucket

      analytics_postgres_server_url = module.rds_postgres_analytics.db_instance_address
      analytics_postgres_db_name    = "analytics"
      auth_postgres_server_url      = module.rds_postgres_auth.db_instance_address
      auth_postgres_db_name         = "auth"
      eks_iam_role_arn              = module.eks_iam_role.iam_role_arn
    },
  )
  secret_provider_class = templatefile(
    "${path.module}/templates/secret-provider-class.tpl.yaml",
    {
      secret_provider_class_name        = local.secret_provider_class_name
      secret_provider_class_secret_name = local.secret_provider_class_secret_name

      secret_name_jwt_signing_key          = aws_secretsmanager_secret.auth_jwt_key.name
      secret_name_auth_db_credentials      = aws_secretsmanager_secret.rds_auth_credentials.name
      secret_name_analytics_db_credentials = aws_secretsmanager_secret.rds_analytics_credentials.name
      secret_name_openai_api_key           = aws_secretsmanager_secret.openai_api_key.name

      secret_name_nebuly_credentials = aws_secretsmanager_secret.nebuly_credentials.name

      k8s_secret_key_auth_db_username      = local.k8s_secret_key_auth_db_username
      k8s_secret_key_auth_db_password      = local.k8s_secret_key_auth_db_password
      k8s_secret_key_analytics_db_username = local.k8s_secret_key_analytics_db_username
      k8s_secret_key_analytics_db_password = local.k8s_secret_key_analytics_db_password
      k8s_secret_key_jwt_signing_key       = local.k8s_secret_key_jwt_signing_key
      k8s_secret_key_openai_api_key        = local.k8s_secret_key_openai_api_key
      k8s_secret_key_nebuly_client_secret  = local.k8s_secret_key_nebuly_client_secret
      k8s_secret_key_nebuly_client_id      = local.k8s_secret_key_nebuly_client_id
    },
  )
}

