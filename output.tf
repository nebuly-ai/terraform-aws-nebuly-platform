### ----------- EKS ----------- ###
output "eks_service_accounts" {
  description = "The service accounts that will able to assume the EKS IAM Role."
  value       = var.eks_service_accounts
}
output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}
output "eks_cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks.cluster_security_group_id
}
output "eks_cluster_name" {
  description = "Kubernetes Cluster Name."
  value       = module.eks.cluster_name
}
output "eks_cluster_get_credentials" {
  description = "Command for getting the credentials for accessing the Kubernetes Cluster."
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}"
}
output "eks_iam_role_arn" {
  description = "The ARN of the EKS IAM role."
  value       = module.eks_iam_role.iam_role_arn
}
