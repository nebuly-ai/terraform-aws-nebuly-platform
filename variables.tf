### General ###
variable "resource_prefix" {
  type        = string
  description = "The prefix that will be used for generating resource names."
}
variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags that will be applied to all resources."
}
variable "region" {
  type        = string
  description = "The region where to provision the resources."
}
variable "secrets_suffix" {
  type        = string
  description = <<EOT
  The suffix that will be appended to the secrets created in AWS Secrets Store. Useful to avoid 
  name collisions. 

  If null, an auto-generated random suffix will be used.
  If empty string, no suffix will be used.
  EOT
  default     = null
}
variable "platform_domain" {
  type        = string
  description = "The domain on which the deployed Nebuly platform is made accessible."
  validation {
    condition     = can(regex("(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\\.)+[a-z0-9][a-z0-9-]{0,61}[a-z0-9]", var.platform_domain))
    error_message = "The domain name must be a valid domain (e.g., example.com)."
  }
}


### External credentials ###
variable "openai_api_key" {
  description = "The API Key used for authenticating with OpenAI."
  type        = string
  default     = null
}
variable "openai_api_key_secret_arn" {
  description = "ARN of an existing Secrets Manager secret containing the OpenAI API key. Mutually exclusive with openai_api_key."
  type        = string
  default     = null

  validation {
    condition = (
      (var.openai_api_key_secret_arn == null && var.openai_api_key != null) ||
      (var.openai_api_key_secret_arn != null && var.openai_api_key == null)
    )
    error_message = "You must specify exactly one of openai_api_key or openai_api_key_secret_arn."
  }

  # ARN format validation
  validation {
    condition = (
      var.openai_api_key_secret_arn == null
      ||
      can(regex(
        "^arn:(aws|aws-us-gov|aws-cn):secretsmanager:[a-z0-9-]+:\\d{12}:secret:[A-Za-z0-9/_+=.@-]+.*$",
        var.openai_api_key_secret_arn
      ))
    )
    error_message = "openai_api_key_secret_arn must be a valid AWS Secrets Manager secret ARN."
  }
}
variable "openai_endpoint" {
  description = "The endpoint of the OpenAI API."
  type        = string
}
variable "openai_gpt4_deployment_name" {
  description = "The name of the deployment to use for the GPT-4 model."
  type        = string
  default     = "gpt-4"
}
variable "nebuly_credentials" {
  type = object({
    client_id : string
    client_secret : string
  })
  description = <<EOT
  The credentials provided by Nebuly are required for activating your platform installation. 
  If you haven't received your credentials or have lost them, please contact support@nebuly.ai.
  EOT
}
variable "okta_sso" {
  description = "Settings for configuring the Okta SSO integration."
  type = object({
    issuer : string
    client_id : string
    client_secret : string
  })
  default = null
}
variable "google_sso" {
  description = "Settings for configuring the Google SSO integration."
  type = object({
    client_id : string
    client_secret : string
    role_mapping : map(string)
  })
  default = null
}


# ------ Kubernetes ------ #
variable "k8s_image_pull_secret_name" {
  default     = "nebuly-docker-pull"
  description = <<EOT
  The name of the Kubernetes Image Pull Secret to use. 
  This value will be used to auto-generate the values.yaml file for installing the Nebuly Platform Helm chart.
  EOT
  type        = string
}


### Networking ###
variable "vpc_id" {
  type        = string
  description = "The ID of the VPC to use."
}
variable "subnet_ids" {
  type        = set(string)
  description = "The IDs of the subnets to attach to the Platform resources."
}
variable "security_group" {
  type = object({
    name = string
    id   = string
  })
  description = "The security group to use."
}
variable "allowed_inbound_cidr_blocks" {
  description = "The CIDR blocks from which inbound connections will be accepted. Use 0.0.0.0/0 for allowing all inbound traffic"
  type        = map(string)
}
variable "create_security_group_rules" {
  description = "If True, add to the specified security group the rules required for allowing connectivity between the provisioned services among all the specified subnets."
  type        = bool
  default     = false
}


### RDS Postgres ###
variable "rds_deletion_protection" {
  description = "If True, enable the deletion protection on the RDS istances."
  type        = bool
  default     = true
}
variable "rds_db_username" {
  description = "The username to connect with the Postgres RDS databases."
  type        = string
  default     = "nebulyadmin"
}
variable "rds_postgres_version" {
  description = "The PostgreSQL version to use for the RDS instances."
  type        = string
  default     = "16"

  validation {
    condition     = contains(["16", "15"], var.rds_postgres_version)
    error_message = "allowed versions are 16, 15"
  }
}
variable "rds_postgres_family" {
  description = "The PostgreSQL family to use for the RDS instances."
  type        = string
  default     = "postgres16"
}
variable "rds_multi_availability_zone_enabled" {
  description = "If True, provision the RDS instances on multiple availability zones."
  type        = bool
  default     = true
}
variable "rds_availability_zone" {
  description = "The availabilty zone of the RDS instances."
  type        = string
  default     = null
}
variable "rds_maintenance_window" {
  description = "The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi'. Eg: 'Mon:00:00-Mon:03:00'."
  type        = string
  default     = "Mon:00:00-Mon:03:00"
}
variable "rds_backup_window" {
  description = "Description: The daily time range (in UTC) during which automated backups are created if they are enabled. Example: '09:46-10:16'. Must not overlap with maintenance_window."
  type        = string
  default     = "03:00-06:00"
}
variable "rds_backup_retention_period" {
  description = "The retention period, in days, of the daily backups."
  type        = number
  default     = 14
}
variable "rds_create_db_subnet_group" {
  type    = bool
  default = true
}
variable "rds_analytics_instance_type" {
  description = "The instance type of the RDS instance hosting the analytics DB."
  type        = string
  default     = "db.m7g.xlarge"
}
variable "rds_analytics_storage" {
  description = "Storage settings of the analytics DB."
  type = object({
    allocated_gb : number
    max_allocated_gb : number
    type : string
    iops : optional(number, null)
  })

  default = {
    allocated_gb     = 32
    max_allocated_gb = 128
    type             = "gp3"
  }

  validation {
    condition     = contains(["gp2", "gp3"], var.rds_analytics_storage.type)
    error_message = "allowed storage types are gp2, gp3"
  }
}
variable "rds_auth_instance_type" {
  description = "The instance type of the RDS instance hosting the auth DB."
  type        = string
  default     = "db.t4g.small"
}
variable "rds_auth_storage" {
  description = "Storage settings of the auth DB."
  type = object({
    allocated_gb : number
    max_allocated_gb : number
    type : string
    iops : optional(number, null)
  })

  default = {
    allocated_gb     = 20 # min available
    max_allocated_gb = 32
    type             = "gp2"
  }

  validation {
    condition     = contains(["gp2", "gp3"], var.rds_auth_storage.type)
    error_message = "allowed storage types are gp2, gp3"
  }
}


### EKS ###
variable "eks_kubernetes_version" {
  description = "Specify which Kubernetes release to use."
  type        = string
  validation {
    condition     = can(regex("1.33|1.32|1.31|1.30", var.eks_kubernetes_version))
    error_message = "allowed versions are 1.33, 1.32, 1.31, 1.30"
  }
}
variable "eks_cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled."
  type        = bool
}
variable "eks_enable_cluster_creator_admin_permissions" {
  description = "Indicates whether or not to add the cluster creator (the identity used by Terraform) as an administrator via access entry."
  type        = bool
  default     = true
}
variable "eks_cloudwatch_observability_enabled" {
  description = <<EOT
  If true, install the CloudWatch Observability add-on.
  The add-on installs the CloudWatch agent to send infrastructure metrics from the cluster, 
  installs Fluent Bit to send container logs, and also enables CloudWatch Application Signals 
  to send application performance telemetry.
  EOT
  type        = bool
  default     = false
}

variable "eks_managed_node_groups" {
  description = "The managed node groups of the EKS cluster."
  type = map(object({
    instance_types = set(string)
    min_size       = number
    max_size       = number
    desired_size   = optional(number)
    subnet_ids     = optional(list(string), null)
    ami_type       = optional(string, "AL2023_x86_64_STANDARD")
    block_device_mappings = optional(map(object({
      device_name = optional(string, "/dev/xvda")
      ebs = optional(object({
        delete_on_termination = optional(bool)
        encrypted             = optional(bool, true)
        volume_size           = optional(number, 128)
        volume_type           = optional(string, "gp3")
      }))
    })))
    disk_size_gb               = optional(number, 128)
    tags                       = optional(map(string), {})
    use_custom_launch_template = optional(bool, true)
    labels                     = optional(map(string), {})
    taints = optional(map(object({
      key    = string
      value  = optional(string)
      effect = string
    })))
  }))
  default = {
    "workers" : {
      instance_types = ["r5.xlarge"]
      min_size       = 1
      max_size       = 1
      desired_size   = 1
      block_device_mappings = {
        sdc = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 128
            volume_type           = "gp3"
            delete_on_termination = true
            encrypted             = true
          }
        }
      }
    }
    "ch-01" : {
      instance_types = ["r7g.xlarge"]
      ami_type       = "AL2023_ARM_64_STANDARD"
      min_size       = 1
      max_size       = 1
      desired_size   = 1
      block_device_mappings = {
        sdc = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 128
            volume_type           = "gp3"
            delete_on_termination = true
            encrypted             = true
          }
        }
      }
      labels = {
        "nebuly.com/reserved" : "clickhouse",
      }
      taints = {
        clickhouse = {
          key = "nebuly.com/reserved"
          value : "clickhouse"
          effect = "NO_SCHEDULE"
        }
      }
    }
    "gpu-a10" : {
      instance_types = ["g5.12xlarge"]
      ami_type       = "AL2023_x86_64_NVIDIA"
      min_size       = 0
      max_size       = 1
      desired_size   = 0
      disk_size_gb   = 128

      block_device_mappings = {
        sdc = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 128
            volume_type           = "gp3"
            delete_on_termination = true
            encrypted             = true
          }
        }
      }

      labels = {
        "nvidia.com/gpu.present" : "true",
        "nebuly.com/accelerator" : "nvidia-ampere-a10",
      }
      tags = {
        "k8s.io/cluster-autoscaler/enabled" : "true",
      }
      taints = {
        gpu = {
          key    = "nvidia.com/gpu"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }
}
variable "eks_service_accounts" {
  description = "The service accounts that will able to assume the EKS IAM Role."
  type = list(object({
    name : string
    namespace : string
  }))
  default = [
    {
      namespace : "kube-system"
      name : "aws-load-balancer-controller"
    },
    {
      namespace : "kube-system"
      name : "cluster-autoscaler"
    },
    {
      namespace : "nebuly"
      name : "cluster-autoscaler"
    },
    {
      namespace : "nebuly-bootstrap"
      name : "cluster-autoscaler"
    },
    {
      namespace : "nebuly"
      name : "aws-load-balancer-controller"
    },
    {
      namespace : "nebuly"
      name : "nebuly"
    },
    {
      namespace : "default"
      name : "nebuly"
    },
  ]
}
variable "eks_cluster_admin_arns" {
  description = "List of ARNs that will be granted the role of Cluster Admin over EKS"
  type        = set(string)
  default     = []
}
variable "eks_enable_prefix_delegation" {
  description = <<EOT
  If true, enable the prefix delegation for the EKS cluster to increase the 
  number of available IP addresses for the pods.

  This should be enabled only if the cluster subnet have limited IP addresses available.

  For more information, see: https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html.
  EOT
  type        = bool
  default     = false
}

### Certificates ###
variable "acm_certificate_arn" {
  type        = string
  default     = null
  description = "If set, use AWS NLB TLS termination with this ACM cert ARN"

  validation {
    condition = (
      var.acm_certificate_arn == null
      || length(trimspace(var.acm_certificate_arn)) == 0
      || can(regex("^arn:aws:acm:[a-z0-9-]+:\\d{12}:certificate\\/[0-9a-f-]+$", trimspace(var.acm_certificate_arn)))
    )
    error_message = "acm_certificate_arn must be a valid ACM certificate ARN, e.g. arn:aws:acm:eu-west-1:123456789012:certificate/<uuid>."
  }
}

