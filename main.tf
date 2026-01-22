terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.23.0"
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

  acm_certificate_arn = var.acm_certificate_arn == null ? "" : trimspace(var.acm_certificate_arn)
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
  _vpc_cni_config_values = var.eks_enable_prefix_delegation ? jsonencode({
    env = {
      ENABLE_PREFIX_DELEGATION = "true"
      WARM_PREFIX_TARGET       = "1"
    }
  }) : null
  base_cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent          = true
      before_compute       = var.eks_enable_prefix_delegation
      configuration_values = local._vpc_cni_config_values
    }
    eks-pod-identity-agent = {
      before_compute = true
      most_recent    = true
    }
    aws-ebs-csi-driver = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"

      pod_identity_association = [
        {
          role_arn        = aws_iam_role.ebs_csi.arn
          service_account = "ebs-csi-controller-sa"
        }
      ]
    }
    aws-efs-csi-driver = {
      most_recent = true
    }
  }
}
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~>21.10.1"

  name               = local.eks_cluster_name
  kubernetes_version = var.eks_kubernetes_version

  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids
  control_plane_subnet_ids = var.subnet_ids

  create_security_group      = var.eks_create_security_group
  security_group_id          = var.eks_cluster_security_group_id
  create_node_security_group = var.eks_create_node_security_group
  node_security_group_id     = var.eks_node_security_group_id

  endpoint_public_access = var.eks_cluster_endpoint_public_access

  enable_cluster_creator_admin_permissions = var.eks_enable_cluster_creator_admin_permissions
  access_entries                           = local.eks_cluster_admin_access_entries

  addons = merge(
    local.base_cluster_addons,
    var.eks_cloudwatch_observability_enabled == true ? {
      amazon-cloudwatch-observability = {
        most_recent = true
      }
    } : {}
  )

  eks_managed_node_groups = {
    for k, obj in var.eks_managed_node_groups : k => {
      name   = k
      labels = obj.labels

      instance_types = obj.instance_types
      taints         = obj.taints

      min_size              = obj.min_size
      max_size              = obj.max_size
      desired_size          = obj.desired_size
      subnet_ids            = obj.subnet_ids == null ? var.subnet_ids : obj.subnet_ids
      ami_type              = obj.ami_type
      block_device_mappings = obj.block_device_mappings
      disk_size             = obj.disk_size_gb

      use_custom_launch_template = obj.use_custom_launch_template
      launch_template_tags       = obj.tags

      enable_monitoring = true

      iam_role_additional_policies = merge(
        {
          # Needed by the aws-ebs-csi-driver
          AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
          # Needed by the aws-efs-csi-driver
          AmazonEFSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
          # Needed by CloudWatch agent
          CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
        },
        obj.use_ecr ? {
          # Needed by ECR access
          AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        } : {}
      )

      tags = obj.tags
      network_interfaces = (
        obj.network_interfaces != null
        ? obj.network_interfaces
        : null
      )
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
  count       = var.create_eks_load_balancer_security_group ? 1 : 0
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
  for_each = var.create_eks_load_balancer_security_group ? var.allowed_inbound_cidr_blocks : {}

  security_group_id = aws_security_group.eks_load_balancer[0].id
  cidr_ipv4         = each.value
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}
resource "aws_vpc_security_group_ingress_rule" "eks_load_balancer_allow_http" {
  for_each = var.create_eks_load_balancer_security_group ? var.allowed_inbound_cidr_blocks : {}

  security_group_id = aws_security_group.eks_load_balancer[0].id
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
locals {
  openai_api_key_secret_provided = var.openai_api_key_secret_arn != null
  # Determine the name of the OpenAI API key secret from arn if provided
  openai_api_key_secret_name = (
    local.openai_api_key_secret_provided ?
    replace(
      element(split(":", trimspace(var.openai_api_key_secret_arn)), 6),
      "/-[A-Za-z0-9]{6}$/",
      ""
    )
    :
    aws_secretsmanager_secret.openai_api_key[0].name
  )
}
resource "aws_secretsmanager_secret" "openai_api_key" {
  count = var.openai_api_key != null ? 1 : 0
  name = (
    local.use_secrets_suffix ?
    format("%s-openai-api-key-%s", var.resource_prefix, local.secrets_suffix) :
    format("%s-openai-api-key", var.resource_prefix)
  )
}
resource "aws_secretsmanager_secret_version" "openai_api_key" {
  count         = var.openai_api_key != null ? 1 : 0
  secret_id     = aws_secretsmanager_secret.openai_api_key[0].id
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
resource "aws_secretsmanager_secret" "microsoft_sso_credentials" {
  count = var.microsoft_sso == null ? 0 : 1

  name = (
    local.use_secrets_suffix ?
    format("%s-microsoft-sso-credentials-%s", var.resource_prefix, local.secrets_suffix) :
    format("%s-microsoft-sso-credentials", var.resource_prefix)
  )
}
resource "aws_secretsmanager_secret_version" "microsoft_sso_credentials" {
  count = var.microsoft_sso == null ? 0 : 1

  secret_id = aws_secretsmanager_secret.microsoft_sso_credentials[0].id
  secret_string = jsonencode(
    {
      "client_id" : var.microsoft_sso.client_id
      "client_secret" : var.microsoft_sso.client_secret
    }
  )
}
resource "aws_secretsmanager_secret" "okta_sso_credentials" {
  count = var.okta_sso == null ? 0 : 1

  name = (
    local.use_secrets_suffix ?
    format("%s-okta-sso-credentials-%s", var.resource_prefix, local.secrets_suffix) :
    format("%s-okta-sso-credentials", var.resource_prefix)
  )
}
resource "aws_secretsmanager_secret_version" "okta_sso_credentials" {
  count = var.okta_sso == null ? 0 : 1

  secret_id = aws_secretsmanager_secret.okta_sso_credentials[0].id
  secret_string = jsonencode(
    {
      "client_id" : var.okta_sso.client_id
      "client_secret" : var.okta_sso.client_secret
    }
  )
}
resource "aws_secretsmanager_secret" "google_sso_credentials" {
  count = var.google_sso == null ? 0 : 1

  name = (
    local.use_secrets_suffix ?
    format("%s-google-sso-credentials-%s", var.resource_prefix, local.secrets_suffix) :
    format("%s-google-sso-credentials", var.resource_prefix)
  )
}
resource "aws_secretsmanager_secret_version" "google_sso_credentials" {
  count = var.google_sso == null ? 0 : 1

  secret_id = aws_secretsmanager_secret.google_sso_credentials[0].id
  secret_string = jsonencode(
    {
      "client_id" : var.google_sso.client_id
      "client_secret" : var.google_sso.client_secret
    }
  )
}


# ---------- Needed by EKS EBS add-on ----------- #
resource "aws_iam_role" "ebs_csi" {
  name = "AmazonEKS_EBS_CSI_DriverRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_attach" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ----------- S3 Storage ----------- #
resource "aws_s3_bucket" "ai_models" {
  bucket_prefix = format("%s-%s", var.resource_prefix, "ai-models")
  tags          = var.tags
}
resource "aws_iam_role_policy_attachment" "ai_models__eks_access" {
  role       = module.eks_iam_role.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
resource "aws_s3_bucket" "backups" {
  bucket_prefix = format("%s-%s", var.resource_prefix, "backups")
  tags          = var.tags
}
resource "aws_iam_role_policy_attachment" "backups__eks_access" {
  role       = module.eks_iam_role.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}


# ------ Post provisioning ------ #
locals {
  secret_provider_class_name        = "nebuly-platform"
  secret_provider_class_secret_name = "nebuly-platform-credentials"

  # k8s secrets keys
  k8s_secret_key_analytics_db_username       = "analytics-db-username"
  k8s_secret_key_analytics_db_password       = "analytics-db-password"
  k8s_secret_key_auth_db_username            = "auth-db-username"
  k8s_secret_key_auth_db_password            = "auth-db-password"
  k8s_secret_key_jwt_signing_key             = "jwt-signing-key"
  k8s_secret_key_openai_api_key              = "openai-api-key"
  k8s_secret_key_nebuly_client_id            = "nebuly-azure-client-id"
  k8s_secret_key_nebuly_client_secret        = "nebuly-azure-client-secret"
  k8s_secret_key_microsoft_sso_client_id     = "microsoft-sso-client-id"
  k8s_secret_key_microsoft_sso_client_secret = "microsoft-sso-client-secret"
  k8s_secret_key_okta_sso_client_id          = "okta-sso-client-id"
  k8s_secret_key_okta_sso_client_secret      = "okta-sso-client-secret"
  k8s_secret_key_google_sso_client_id        = "google-sso-client-id"
  k8s_secret_key_google_sso_client_secret    = "google-sso-client-secret"

  bootstrap_helm_values = templatefile(
    "${path.module}/templates/helm-values-bootstrap.tpl.yaml",
    {
      eks_region          = var.region
      eks_cluster_name    = local.eks_cluster_name
      eks_iam_role_arn    = module.eks_iam_role.iam_role_arn
      acm_certificate_arn = local.acm_certificate_arn
    }
  )
  helm_values = templatefile(
    "${path.module}/templates/helm-values.tpl.yaml",
    {
      platform_domain        = var.platform_domain
      image_pull_secret_name = var.k8s_image_pull_secret_name
      aws_region             = var.region

      openai_endpoint         = var.openai_endpoint
      openai_gpt4o_deployment = var.openai_gpt4_deployment_name

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

      okta_sso_enabled                      = var.okta_sso != null
      okta_sso_issuer                       = var.okta_sso != null ? var.okta_sso.issuer : ""
      k8s_secret_key_okta_sso_client_id     = local.k8s_secret_key_okta_sso_client_id
      k8s_secret_key_okta_sso_client_secret = local.k8s_secret_key_okta_sso_client_secret

      google_sso_enabled                      = var.google_sso != null
      google_sso_role_mapping                 = var.google_sso != null ? join(",", [for role, group in var.google_sso.role_mapping : "${role}:${group}"]) : ""
      k8s_secret_key_google_sso_client_id     = local.k8s_secret_key_google_sso_client_id
      k8s_secret_key_google_sso_client_secret = local.k8s_secret_key_google_sso_client_secret

      microsoft_sso_enabled                      = var.microsoft_sso != null
      microsoft_sso_tenant_id                    = var.microsoft_sso != null ? var.microsoft_sso.tenant_id : ""
      microsoft_sso_role_mapping                 = var.microsoft_sso != null ? join(",", [for role, group in var.microsoft_sso.role_mapping : "${role}:${group}"]) : ""
      k8s_secret_key_microsoft_sso_client_id     = local.k8s_secret_key_microsoft_sso_client_id
      k8s_secret_key_microsoft_sso_client_secret = local.k8s_secret_key_microsoft_sso_client_secret

      s3_bucket_name                    = aws_s3_bucket.ai_models.bucket
      clickhouse_backups_s3_bucket_name = aws_s3_bucket.backups.bucket

      analytics_postgres_server_url = module.rds_postgres_analytics.db_instance_address
      analytics_postgres_db_name    = "analytics"
      auth_postgres_server_url      = module.rds_postgres_auth.db_instance_address
      auth_postgres_db_name         = "auth"
      eks_iam_role_arn              = module.eks_iam_role.iam_role_arn

      acm_certificate_arn = local.acm_certificate_arn
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
      secret_name_openai_api_key           = local.openai_api_key_secret_name
      secret_name_okta_sso_credentials     = var.okta_sso == null ? "" : aws_secretsmanager_secret.okta_sso_credentials[0].name
      secret_name_microsoft_sso_credentials = var.microsoft_sso == null ? "" : aws_secretsmanager_secret.microsoft_sso_credentials[0].name

      secret_name_nebuly_credentials = aws_secretsmanager_secret.nebuly_credentials.name

      okta_sso_enabled                      = var.okta_sso != null
      k8s_secret_key_okta_sso_client_id     = local.k8s_secret_key_okta_sso_client_id
      k8s_secret_key_okta_sso_client_secret = local.k8s_secret_key_okta_sso_client_secret

      microsoft_sso_enabled                      = var.microsoft_sso != null
      k8s_secret_key_microsoft_sso_client_id     = local.k8s_secret_key_microsoft_sso_client_id
      k8s_secret_key_microsoft_sso_client_secret = local.k8s_secret_key_microsoft_sso_client_secret

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

