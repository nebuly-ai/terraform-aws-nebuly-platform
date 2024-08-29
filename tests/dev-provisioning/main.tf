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
variable "nebuly_credentials" {
  type = object({
    client_id     = string
    client_secret = string
  })
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

  openai_gpt4_deployment_name = "gpt-4"
  openai_endpoint             = "https://test.nebuly.com"
  openai_api_key              = "test"

  nebuly_credentials          = var.nebuly_credentials
  platform_domain             = "platform.aws.testing.nebuly.com"
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
output "helm_values" {
  value = module.main.helm_values
  sensitive = true
}
output "helm_values_bootstrap" {
  value = module.main.helm_values_bootstrap
  sensitive = true
}
output "secret_provider_class" {
  value = module.main.secret_provider_class
  sensitive = true
}
