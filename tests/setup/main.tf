terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.23.0"
    }
  }
}



### ----------- Data Sources ----------- ###
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


### ----------- Outputs ----------- ###
output "aws_vpc" {
  value = data.aws_vpc.default
}
output "aws_subnets" {
  value = data.aws_subnets.default
}
output "aws_security_group" {
  value = data.aws_security_group.default
}
