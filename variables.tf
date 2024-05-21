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


### External credentials ###
variable "openai_api_key" {
  description = "The API Key used for authenticating with OpenAI."
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


### RDS Postgres ###
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
    type             = "gp2"
  }

  validation {
    condition     = contains(["gp2", "gp3"], var.rds_analytics_storage.type)
    error_message = "allowed storage types are gp2, gp3"
  }
}
variable "rds_auth_instance_type" {
  description = "The instance type of the RDS instance hosting the auth DB."
  type        = string
  default     = "t4g.small"
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
variable "eks_managed_node_group_defaults" {
  description = "The default settings of the EKS managed node groups."
  type = object({
    ami_type = string
  })
  default = {
    ami_type = "AL2_x86_64"
  }
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
    use_custom_launch_template = optional(bool, false)
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
      subnet_ids     = [local.subnet_eu_central_1b]
      disk_size_gb   = 128
      min_size       = 1
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
    "gpu-a100" : {
      instance_types = ["p4d.24xlarge"]
      ami_type       = "AL2_x86_64_GPU"
      min_size       = 0
      max_size       = 1
      desired_size   = 0
      subnet_ids     = [local.subnet_eu_central_1b]
      disk_size_gb   = 128

      labels = {
        "nvidia.com/gpu.present" : "true",
        "nebuly.com/accelerator" : "nvidia-ampere-a100",
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
      name : "cluster-autoscaler"
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
