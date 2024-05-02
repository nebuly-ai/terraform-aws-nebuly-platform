run "setup" {
  module  {
    source = "./tests/setup"
  }
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

run "smoke_test_plan" {
  command = plan
}
