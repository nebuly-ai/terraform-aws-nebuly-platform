### General ###
variable "resource_prefix" {
  type = string
}
variable "region" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}

### AWS Auth ###
variable "aws_access_key" {
  type = string
}
variable "aws_secret_key" {
  type = string
}

### Budget ###
variable "budget_monthly_usd" {
  type        = string
  description = "Monthly budget, in Euro."
}
variable "budget_notification_receivers" {
  type        = set(string)
  description = "List of emails of the users that will receive budget notifications."
}
