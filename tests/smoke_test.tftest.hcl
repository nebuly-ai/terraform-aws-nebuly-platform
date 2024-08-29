provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

run "setup" {
  module {
    source = "./tests/setup"
  }
}

run "smoke_test_plan" {
  command = plan

  variables {
    vpc_id         = run.setup.aws_vpc.id
    subnet_ids     = run.setup.aws_subnets.ids
    security_group = run.setup.aws_security_group

    allowed_inbound_cidr_blocks = {
      "all" : "0.0.0.0/0"
    }

    platform_domain = "test.nebuly.com"

    openai_api_key              = "test"
    openai_endpoint             = "https://test.nebuly.com"
    openai_gpt4_deployment_name = "test"

    nebuly_credentials = {
      client_id     = "test"
      client_secret = "test"
    }
  }

}
