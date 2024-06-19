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
  version = "0.2.8"

  security_group = data.aws_security_group.default

  eks_cloudwatch_observability_enabled = true
  eks_cluster_endpoint_public_access   = true
  eks_kubernetes_version               = "1.28"
  allowed_inbound_cidr_blocks          = {}

  rds_multi_availability_zone_enabled = false
  rds_availability_zone               = var.availability_zones[0]

  vpc_id          = data.aws_vpc.default.id
  region          = var.region
  subnet_ids      = data.aws_subnets.default.ids
  resource_prefix = "nebuly"
  openai_api_key  = "my-key"
}

