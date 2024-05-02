### General ###
region          = "eu-central-1"
resource_prefix = "nbllab"
tags = {
  "env" : "dev"
  "project" : "self-deploy"
}

### Budget ###
budget_monthly_usd = 100
budget_notification_receivers = [
  "m.zanotti@nebuly.ai",
  "d.fiori@nebuly.ai",
]
