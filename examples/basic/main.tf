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


# ----------- Terraform setup ----------- #
terraform {
  required_version = ">1.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.45"
    }
  }
}
provider "aws" {
  access_key = "<access-key>"
  secret_key = "<secret-key>"
  region     = "us-east-1"
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
}
data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}


# ------ Main ------ #
module "main" {
  source  = "nebuly-ai/nebuly-platform/aws"
  version = "0.5.1"

  security_group = data.aws_security_group.default

  eks_cloudwatch_observability_enabled = true
  eks_cluster_endpoint_public_access   = true
  eks_kubernetes_version               = "1.31"
  allowed_inbound_cidr_blocks          = {}

  rds_multi_availability_zone_enabled = false
  rds_availability_zone               = var.availability_zones[0]

  openai_endpoint             = "<your-openai-endpoint>"
  openai_gpt4_deployment_name = "<your-openai-gpt4-deployment-name>"
  platform_domain             = "your.domain.com"
  nebuly_credentials = {
    client_id     = "<your-nebuly-client-id>"
    client_secret = "<your-nebuly-client-secret>"
  }

  vpc_id          = data.aws_vpc.default.id
  region          = var.region
  subnet_ids      = data.aws_subnets.default.ids
  resource_prefix = "nebuly"
  openai_api_key  = "my-key"
}


# ------ Outputs ------ #
output "helm_values_bootstrap" {
  value       = module.main.helm_values_bootstrap
  sensitive   = true
  description = <<EOT
  The `bootrap.values.yaml` file for installing the Nebuly AWS Boostrap chart with Helm.
  EOT
}
output "helm_values" {
  value       = module.main.helm_values
  sensitive   = true
  description = <<EOT
  The `values.yaml` file for installing Nebuly with Helm.

  The default standard configuration is used, which uses Nginx as ingress controller and exposes the application to the Internet. This configuration can be customized according to specific needs.
  EOT
}
output "secret_provider_class" {
  value       = module.main.secret_provider_class
  sensitive   = true
  description = "The `secret-provider-class.yaml` file to make Kubernetes reference the secrets stored in the Key Vault."
}
output "eks_cluster_get_credentials" {
  description = "Command for getting the credentials for accessing the Kubernetes Cluster."
  value       = module.main.eks_cluster_get_credentials
}
