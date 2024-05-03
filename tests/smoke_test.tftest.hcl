provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

run "setup" {
  module  {
    source = "./tests/setup"
  }
}

run "smoke_test_plan" {
  command = plan

  variables {
    vpc_id = run.setup.aws_vpc.id
    subnet_ids = run.setup.aws_subnets.ids
  }

}
