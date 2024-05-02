locals {
  cluster_name = "${var.resource_prefix}eks"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~>20.8"

  cluster_name    = local.cluster_name
  cluster_version = "1.29"

  vpc_id                         = data.aws_vpc.default.id
  subnet_ids                     = data.aws_subnets.default.ids
  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

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

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 1
    }
  }

  tags = var.tags
}


module "iam_eks_role" {
  # Role for reading from AWS Secrets Manager trhough ASCP
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~>5.39"

  role_name = "secrets-reader"

  attach_external_secrets_policy                     = true
  external_secrets_secrets_manager_create_permission = true

  oidc_providers = {
    one = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "nebuly:nebulyplatform",
        "default:nebuly",
      ]
    }
  }
}

### Outputs ###
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}
output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}
output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}
output "cluster_get_credentials" {
  description = "Command for getting the credentials for accessing the Kubernetes Cluster"
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}"
}
output "cluster_role_arn" {
  value = module.iam_eks_role.iam_role_arn
}
