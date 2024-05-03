terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.45"
    }
  }
}

locals {
  eks_cluster_name = "${var.resource_prefix}eks"
  eks_tags = merge(var.tags, {
    "platform.nebuly.com/component" : "eks"
  })
}


### ----------- EKS ----------- ###
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~>20.8.5"

  cluster_name    = local.eks_cluster_name
  cluster_version = var.eks_kubernetes_version

  vpc_id                         = var.vpc_id
  subnet_ids                     = var.subnet_ids
  cluster_endpoint_public_access = var.eks_cluster_endpoint_public_access

  enable_cluster_creator_admin_permissions = var.eks_enable_cluster_creator_admin_permissions

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  eks_managed_node_group_defaults = var.eks_managed_node_group_defaults

  eks_managed_node_groups = {
    for k, obj in var.eks_managed_node_groups : k => {
      name = k

      instance_types = obj.instance_types

      min_size     = obj.min_size
      max_size     = obj.max_size
      desired_size = obj.desired_size
    }
  }

  tags = local.eks_tags
}
module "eks_iam_role" {
  # Role for reading from AWS Secrets Manager trhough ASCP
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~>5.39.0"

  role_name = local.eks_cluster_name

  attach_external_secrets_policy                     = true
  external_secrets_secrets_manager_create_permission = true

  oidc_providers = {
    one = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        for obj in var.eks_service_accounts :
        format("%s:%s", obj.namespace, obj.name)
      ]
    }
  }

  tags = local.eks_tags
}

