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


### Networking ###
variable "vpc_id" {
  type        = string
  description = "The ID of the VPC to use."
}
variable "subnet_ids" {
  type        = set(string)
  description = "The IDs of the subnets to attach to the Platform resources."
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
    instance_types = set(string)
    min_size       = number
    max_size       = number
    desired_size   = optional(number)
  }))
  default = {
    "workers" : {
      instance_types = ["r5.xlarge"]
      min_size       = 3
      max_size       = 3
      desired_size   = 3
    }
    "gpu-a100" : {
      instance_types = ["p4d.24xlarge"]
      min_size       = 0
      max_size       = 1
      desired_size   = 0
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
      namespace : "nebuly"
      name : "nebuly"
    },
    {
      namespace : "default"
      name : "nebuly"
    },
  ]
}
