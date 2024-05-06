### Variables ###
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

### Data Sources ###
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
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

### Main ###
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}
module "main" {
  source = "../../"

  eks_cluster_endpoint_public_access = true
  eks_kubernetes_version             = "1.28"

  vpc_id          = data.aws_vpc.default.id
  region          = var.region
  subnet_ids      = data.aws_subnets.default.ids
  resource_prefix = "nbllab"
  openai_api_key  = "test"
}
