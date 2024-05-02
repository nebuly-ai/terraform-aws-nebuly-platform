run "setup" {
  module  {
    source = "./tests/setup"
  }
}

run "smoke_test_plan" {
  command = plan
}
