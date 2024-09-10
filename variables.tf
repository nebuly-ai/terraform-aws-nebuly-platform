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
}
variable "openai_endpoint" {
  description = "The endpoint of the OpenAI API."
  type        = string
}
variable "openai_gpt4_deployment_name" {
  description = "The name of the deployment to use for the GPT-4 model."
  type        = string
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
variable "eks_managed_node_group_defaults" {
  description = "The default settings of the EKS managed node groups."
  type = object({
    ami_type              = string
    block_device_mappings = map(any)
  })
  default = {
    ami_type = "AL2_x86_64"
    block_device_mappings = {
      sdc = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 128
          volume_type           = "gp2"
          delete_on_termination = true
        }
      }
  } }
}
variable "eks_managed_node_groups" {
  description = "The managed node groups of the EKS cluster."
  type = map(object({
    instance_types             = set(string)
    min_size                   = number
    max_size                   = number
    desired_size               = optional(number)
    subnet_ids                 = optional(list(string), null)
    ami_type                   = optional(string, "AL2_x86_64")
    disk_size_gb               = optional(number, 128)
    tags                       = optional(map(string), {})
    use_custom_launch_template = optional(bool, true)
    labels                     = optional(map(string), {})
    taints = optional(set(object({
      key : string
      value : string
      effect : string
    })), [])
  }))
  default = {
    "workers" : {
      instance_types = ["r5.xlarge"]
      min_size       = 1
      max_size       = 1
      desired_size   = 1
    }
    "gpu-t4" : {
      instance_types = ["g4dn.xlarge"]
      ami_type       = "AL2_x86_64_GPU"
      disk_size_gb   = 128
      min_size       = 0
      max_size       = 1
      desired_size   = 1

      labels = {
        "nvidia.com/gpu.present" : "true",
        "nebuly.com/accelerator" : "nvidia-tesla-t4",
      }
      taints = [
        {
          key : "nvidia.com/gpu"
          value : ""
          effect : "NO_SCHEDULE"
        }
      ]
    }
    "gpu-a10" : {
      instance_types = ["g5.12xlarge"]
      ami_type       = "AL2_x86_64_GPU"
      min_size       = 0
      max_size       = 1
      desired_size   = 0
      disk_size_gb   = 128

      labels = {
        "nvidia.com/gpu.present" : "true",
        "nebuly.com/accelerator" : "nvidia-ampere-a10",
      }
      tags = {
        "k8s.io/cluster-autoscaler/enabled" : "true",
      }
      taints = [
        {
          key : "nvidia.com/gpu"
          value : ""
          effect : "NO_SCHEDULE"
        }
      ]
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
