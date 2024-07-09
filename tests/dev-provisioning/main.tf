# ----------- Terraform setup ----------- #
terraform {
  required_version = ">1.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.45"
    }
    null = {
      source  = "hashicorp/null"
      version = "~>3.2"
    }
  }
}


# ------ Variables ------ #
variable "aws_access_key" {
  type = string
}
variable "aws_secret_key" {
  type = string
}
variable "region" {
  type    = string
  default = "us-east-1"
}
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}


# ------ Data Sources ------ #
data "aws_vpc" "default" {
  default = true
}
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availabilityZone"
    values = var.availability_zones
  }
}
data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}

### Main ###
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}


module "main" {
  source = "../../"

  security_group = data.aws_security_group.default

  eks_cloudwatch_observability_enabled = true
  eks_cluster_endpoint_public_access   = true
  eks_kubernetes_version               = "1.28"
  eks_managed_node_groups = {
    "workers" : {
      instance_types = ["r5.xlarge"]
      min_size       = 1
      max_size       = 1
      desired_size   = 1
    }
    "gpu-a100" : {
      instance_types = ["p4d.24xlarge"]
      min_size       = 0
      max_size       = 1
      desired_size   = 0
    }
  }
  allowed_inbound_cidr_blocks = {
    "all" : "0.0.0.0/0"
  }

  secrets_suffix = null

  rds_multi_availability_zone_enabled = false
  rds_deletion_protection             = false
  rds_availability_zone               = var.availability_zones[0]
  rds_analytics_instance_type         = "db.t4g.micro"
  rds_analytics_storage = {
    allocated_gb     = 20
    max_allocated_gb = 20
    type             = "gp2"
  }
  rds_auth_instance_type = "db.t4g.micro"
  rds_auth_storage = {
    allocated_gb     = 20
    max_allocated_gb = 20
    type             = "gp2"
  }
  rds_create_db_subnet_group = true

  create_security_group_rules = true
  vpc_id                      = data.aws_vpc.default.id
  region                      = var.region
  subnet_ids                  = data.aws_subnets.default.ids
  resource_prefix             = "nbllab"
  openai_api_key              = "test"
}


# ------ Outputs ------ #
output "eks_iam_role_arn" {
  description = "The ARN of the EKS IAM role."
  value       = module.main.eks_iam_role_arn
}
output "eks_cluster_get_credentials" {
  description = "Command for getting the credentials for accessing the Kubernetes Cluster."
  value       = module.main.eks_cluster_get_credentials
}
output "eks_cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.main.eks_cluster_security_group_id
}
output "secret_names" {
  value = {
    "auth_jwt_key" : module.main.auth_jwt_key_secret_name
    "openai_api_key" : module.main.openai_api_key_secret_name
    "auth_db" : module.main.auth_db.password_secret_name
    "analytics_db" : module.main.analytics_db.password_secret_name
  }
}
output "s3_bucket_ai_models" {
  value = module.main.s3_bucket_ai_models
}
output "auth_db" {
  value = module.main.auth_db
}
output "analytics_db" {
  value = module.main.analytics_db
}
